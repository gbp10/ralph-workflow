#!/bin/bash
# checkpoint.sh - Checkpoint/Resume System for Ralph Orchestrator
#
# Enables resuming execution after crashes, interruptions, or context window exhaustion.
# Saves state after each story completion and allows resuming from any point.
#
# Usage:
#   source checkpoint.sh
#   init_checkpoint "feature-name"
#   save_checkpoint "STORY-001" "completed" 3 0.42
#   resume_from_checkpoint  # Returns story_id to resume from

set -euo pipefail

# Directory for checkpoint files
CHECKPOINT_DIR="${RALPH_DIR:-$(pwd)/ralph}/state"
CHECKPOINT_FILE=""

# Colors for output
CHECKPOINT_GREEN='\033[0;32m'
CHECKPOINT_YELLOW='\033[1;33m'
CHECKPOINT_BLUE='\033[0;34m'
CHECKPOINT_NC='\033[0m'

# Initialize checkpoint system for a feature
init_checkpoint() {
    local feature="$1"
    local budget_limit="${2:-10.00}"

    mkdir -p "$CHECKPOINT_DIR"
    CHECKPOINT_FILE="$CHECKPOINT_DIR/checkpoint-${feature}.json"

    # Create new checkpoint if doesn't exist
    if [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo -e "${CHECKPOINT_BLUE}Creating new checkpoint for: $feature${CHECKPOINT_NC}"
        cat > "$CHECKPOINT_FILE" << EOF
{
    "version": "1.0",
    "feature": "$feature",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "current_story_id": null,
    "stories": {},
    "total_cost_usd": 0,
    "budget_limit_usd": $budget_limit
}
EOF
    else
        echo -e "${CHECKPOINT_YELLOW}Resuming from existing checkpoint: $CHECKPOINT_FILE${CHECKPOINT_NC}"
    fi

    export CHECKPOINT_FILE
}

# Get the checkpoint file path
get_checkpoint_file() {
    echo "$CHECKPOINT_FILE"
}

# Save checkpoint after story state change
save_checkpoint() {
    local story_id="$1"
    local status="$2"
    local iterations="${3:-0}"
    local cost="${4:-0}"

    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo -e "${CHECKPOINT_YELLOW}Warning: No checkpoint file initialized${CHECKPOINT_NC}" >&2
        return 1
    fi

    local tmp_file=$(mktemp)

    # Update checkpoint with new story state
    jq --arg id "$story_id" \
       --arg s "$status" \
       --argjson i "$iterations" \
       --argjson c "$cost" \
       --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '
       .stories[$id] = {
           status: $s,
           iterations: $i,
           cost_usd: $c,
           updated_at: $now
       } |
       .last_updated = $now |
       (if $s == "in_progress" then .current_story_id = $id else . end) |
       (if $s == "completed" then .current_story_id = null else . end) |
       .total_cost_usd = ([.stories[].cost_usd] | add)
       ' "$CHECKPOINT_FILE" > "$tmp_file"

    mv "$tmp_file" "$CHECKPOINT_FILE"
    echo -e "${CHECKPOINT_GREEN}✓ Checkpoint saved: $story_id ($status)${CHECKPOINT_NC}"
}

# Mark story as in_progress
start_story() {
    local story_id="$1"
    save_checkpoint "$story_id" "in_progress" 0 0
}

# Mark story as completed with metrics
complete_story() {
    local story_id="$1"
    local iterations="$2"
    local cost="${3:-0}"
    save_checkpoint "$story_id" "completed" "$iterations" "$cost"
}

# Mark story as failed
fail_story() {
    local story_id="$1"
    local iterations="$2"
    local cost="${3:-0}"
    save_checkpoint "$story_id" "failed" "$iterations" "$cost"
}

# Get resume point (returns story_id or empty)
get_resume_point() {
    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo ""
        return
    fi

    # Check for in_progress story first
    local in_progress=$(jq -r '.current_story_id // empty' "$CHECKPOINT_FILE")
    if [[ -n "$in_progress" ]]; then
        echo "$in_progress"
        return
    fi

    # Otherwise, find first non-completed story from stories file
    # This requires the stories file to be passed
    echo ""
}

# Get story checkpoint status
get_story_status() {
    local story_id="$1"

    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo "pending"
        return
    fi

    local status=$(jq -r --arg id "$story_id" '.stories[$id].status // "pending"' "$CHECKPOINT_FILE")
    echo "$status"
}

# Get story iteration count from checkpoint
get_story_iterations() {
    local story_id="$1"

    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo "0"
        return
    fi

    local iterations=$(jq -r --arg id "$story_id" '.stories[$id].iterations // 0' "$CHECKPOINT_FILE")
    echo "$iterations"
}

# Check if budget is exceeded
check_budget() {
    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        return 0  # No budget check without checkpoint
    fi

    local current=$(jq '.total_cost_usd // 0' "$CHECKPOINT_FILE")
    local limit=$(jq '.budget_limit_usd // 10' "$CHECKPOINT_FILE")

    if (( $(echo "$current >= $limit" | bc -l) )); then
        echo -e "${CHECKPOINT_YELLOW}⚠️ Budget exceeded! Current: \$${current}, Limit: \$${limit}${CHECKPOINT_NC}" >&2
        return 1
    fi

    return 0
}

# Get checkpoint summary
get_checkpoint_summary() {
    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo "No checkpoint available"
        return
    fi

    local feature=$(jq -r '.feature' "$CHECKPOINT_FILE")
    local started=$(jq -r '.started_at' "$CHECKPOINT_FILE")
    local last_updated=$(jq -r '.last_updated' "$CHECKPOINT_FILE")
    local total_cost=$(jq '.total_cost_usd // 0' "$CHECKPOINT_FILE")
    local budget=$(jq '.budget_limit_usd // 10' "$CHECKPOINT_FILE")
    local completed=$(jq '[.stories | to_entries[] | select(.value.status == "completed")] | length' "$CHECKPOINT_FILE")
    local in_progress=$(jq '[.stories | to_entries[] | select(.value.status == "in_progress")] | length' "$CHECKPOINT_FILE")
    local failed=$(jq '[.stories | to_entries[] | select(.value.status == "failed")] | length' "$CHECKPOINT_FILE")

    cat << EOF
╔═══════════════════════════════════════════════════════════╗
║                  Checkpoint Summary                        ║
╠═══════════════════════════════════════════════════════════╣
  Feature:      $feature
  Started:      $started
  Last Updated: $last_updated

  Stories:
    ✓ Completed:   $completed
    ⏳ In Progress: $in_progress
    ✗ Failed:      $failed

  Cost:
    Total:  \$$total_cost
    Budget: \$$budget
╚═══════════════════════════════════════════════════════════╝
EOF
}

# Reset checkpoint for a feature (use with caution)
reset_checkpoint() {
    local feature="$1"
    local budget_limit="${2:-10.00}"

    if [[ -n "$CHECKPOINT_FILE" ]] && [[ -f "$CHECKPOINT_FILE" ]]; then
        echo -e "${CHECKPOINT_YELLOW}Resetting checkpoint for: $feature${CHECKPOINT_NC}"
        rm -f "$CHECKPOINT_FILE"
    fi

    init_checkpoint "$feature" "$budget_limit"
}

# Should story be skipped (already completed)?
should_skip_story() {
    local story_id="$1"
    local status=$(get_story_status "$story_id")

    if [[ "$status" == "completed" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Export checkpoint to a portable format (for CI/CD handoff)
export_checkpoint() {
    local output_file="${1:-checkpoint-export.json}"

    if [[ -z "$CHECKPOINT_FILE" ]] || [[ ! -f "$CHECKPOINT_FILE" ]]; then
        echo "No checkpoint to export" >&2
        return 1
    fi

    cp "$CHECKPOINT_FILE" "$output_file"
    echo -e "${CHECKPOINT_GREEN}✓ Checkpoint exported to: $output_file${CHECKPOINT_NC}"
}

# Import checkpoint from a file
import_checkpoint() {
    local input_file="$1"

    if [[ ! -f "$input_file" ]]; then
        echo "Checkpoint file not found: $input_file" >&2
        return 1
    fi

    # Validate it's a valid checkpoint
    if ! jq -e '.version and .feature and .stories' "$input_file" > /dev/null 2>&1; then
        echo "Invalid checkpoint file format" >&2
        return 1
    fi

    local feature=$(jq -r '.feature' "$input_file")
    mkdir -p "$CHECKPOINT_DIR"
    CHECKPOINT_FILE="$CHECKPOINT_DIR/checkpoint-${feature}.json"

    cp "$input_file" "$CHECKPOINT_FILE"
    export CHECKPOINT_FILE
    echo -e "${CHECKPOINT_GREEN}✓ Checkpoint imported: $feature${CHECKPOINT_NC}"
}
