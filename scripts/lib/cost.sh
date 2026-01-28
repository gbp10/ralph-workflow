#!/bin/bash
# cost.sh - Cost Tracking System for Ralph Orchestrator
#
# Tracks API costs based on token usage and model selection.
# Provides budget enforcement and cost reporting.
#
# Usage:
#   source cost.sh
#   estimate_cost 12000 3500 "sonnet"
#   track_story_cost "STORY-001" 12000 3500 "sonnet"
#   get_total_cost

set -euo pipefail

# Cost per 1K tokens (as of 2025-01)
# Claude Sonnet 3.5/4
declare -A COST_INPUT=(
    ["opus"]=0.015
    ["sonnet"]=0.003
    ["haiku"]=0.00025
)

declare -A COST_OUTPUT=(
    ["opus"]=0.075
    ["sonnet"]=0.015
    ["haiku"]=0.00125
)

# Default model if not specified
DEFAULT_MODEL="sonnet"

# Cost tracking state
COST_TRACKING_FILE=""
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0
TOTAL_COST_USD=0

# Initialize cost tracking
init_cost_tracking() {
    local feature="${1:-default}"
    local ralph_dir="${RALPH_DIR:-$(pwd)/ralph}"

    mkdir -p "$ralph_dir/state"
    COST_TRACKING_FILE="$ralph_dir/state/cost-${feature}.json"

    # Create or load existing cost file
    if [[ ! -f "$COST_TRACKING_FILE" ]]; then
        cat > "$COST_TRACKING_FILE" << EOF
{
    "feature": "$feature",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "stories": {},
    "totals": {
        "input_tokens": 0,
        "output_tokens": 0,
        "cost_usd": 0
    }
}
EOF
    fi

    # Load totals from file
    TOTAL_INPUT_TOKENS=$(jq '.totals.input_tokens // 0' "$COST_TRACKING_FILE")
    TOTAL_OUTPUT_TOKENS=$(jq '.totals.output_tokens // 0' "$COST_TRACKING_FILE")
    TOTAL_COST_USD=$(jq '.totals.cost_usd // 0' "$COST_TRACKING_FILE")

    export COST_TRACKING_FILE
}

# Estimate cost for a given token count
estimate_cost() {
    local input_tokens="${1:-0}"
    local output_tokens="${2:-0}"
    local model="${3:-$DEFAULT_MODEL}"

    # Get cost rates for model
    local input_rate="${COST_INPUT[$model]:-${COST_INPUT[sonnet]}}"
    local output_rate="${COST_OUTPUT[$model]:-${COST_OUTPUT[sonnet]}}"

    # Calculate cost
    local input_cost=$(echo "scale=6; $input_tokens * $input_rate / 1000" | bc)
    local output_cost=$(echo "scale=6; $output_tokens * $output_rate / 1000" | bc)
    local total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)

    echo "$total_cost"
}

# Track cost for a story
track_story_cost() {
    local story_id="$1"
    local input_tokens="${2:-0}"
    local output_tokens="${3:-0}"
    local model="${4:-$DEFAULT_MODEL}"

    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "Warning: Cost tracking not initialized" >&2
        return 1
    fi

    # Calculate cost
    local cost=$(estimate_cost "$input_tokens" "$output_tokens" "$model")

    # Update running totals
    TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
    TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))
    TOTAL_COST_USD=$(echo "scale=6; $TOTAL_COST_USD + $cost" | bc)

    # Update file
    local tmp_file=$(mktemp)
    jq --arg id "$story_id" \
       --argjson tin "$input_tokens" \
       --argjson tout "$output_tokens" \
       --arg model "$model" \
       --argjson cost "$cost" \
       --argjson total_in "$TOTAL_INPUT_TOKENS" \
       --argjson total_out "$TOTAL_OUTPUT_TOKENS" \
       --argjson total_cost "$TOTAL_COST_USD" \
       --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '
       .stories[$id] = (.stories[$id] // {input_tokens: 0, output_tokens: 0, cost_usd: 0, entries: []}) |
       .stories[$id].input_tokens += $tin |
       .stories[$id].output_tokens += $tout |
       .stories[$id].cost_usd += $cost |
       .stories[$id].entries += [{
           timestamp: $now,
           model: $model,
           input_tokens: $tin,
           output_tokens: $tout,
           cost_usd: $cost
       }] |
       .totals = {
           input_tokens: $total_in,
           output_tokens: $total_out,
           cost_usd: $total_cost
       } |
       .last_updated = $now
       ' "$COST_TRACKING_FILE" > "$tmp_file"

    mv "$tmp_file" "$COST_TRACKING_FILE"

    echo "$cost"
}

# Track iteration cost (simpler interface)
track_iteration_cost() {
    local story_id="$1"
    local input_tokens="${2:-0}"
    local output_tokens="${3:-0}"

    track_story_cost "$story_id" "$input_tokens" "$output_tokens" "$DEFAULT_MODEL"
}

# Get total cost so far
get_total_cost() {
    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "0"
        return
    fi

    jq '.totals.cost_usd // 0' "$COST_TRACKING_FILE"
}

# Get cost for a specific story
get_story_cost() {
    local story_id="$1"

    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "0"
        return
    fi

    jq -r --arg id "$story_id" '.stories[$id].cost_usd // 0' "$COST_TRACKING_FILE"
}

# Check if budget exceeded
is_budget_exceeded() {
    local budget="${1:-10.00}"
    local current=$(get_total_cost)

    if (( $(echo "$current >= $budget" | bc -l) )); then
        return 0  # True - exceeded
    else
        return 1  # False - within budget
    fi
}

# Get cost breakdown by story
get_cost_breakdown() {
    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "No cost data available"
        return
    fi

    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                   Cost Breakdown                          ║"
    echo "╠═══════════════════════════════════════════════════════════╣"

    jq -r '
        .stories | to_entries | sort_by(.key) | .[] |
        "  \(.key): $\(.value.cost_usd | tostring | .[0:6]) (\(.value.input_tokens)in/\(.value.output_tokens)out)"
    ' "$COST_TRACKING_FILE"

    echo "╠═══════════════════════════════════════════════════════════╣"

    local totals=$(jq '.totals' "$COST_TRACKING_FILE")
    local total_cost=$(echo "$totals" | jq '.cost_usd')
    local total_in=$(echo "$totals" | jq '.input_tokens')
    local total_out=$(echo "$totals" | jq '.output_tokens')

    echo "  TOTAL: \$$total_cost ($total_in input / $total_out output tokens)"
    echo "╚═══════════════════════════════════════════════════════════╝"
}

# Get cost summary as JSON
get_cost_summary_json() {
    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "{}"
        return
    fi

    jq '{
        feature: .feature,
        total_cost_usd: .totals.cost_usd,
        total_input_tokens: .totals.input_tokens,
        total_output_tokens: .totals.output_tokens,
        story_count: (.stories | length),
        avg_cost_per_story: (if (.stories | length) > 0 then (.totals.cost_usd / (.stories | length)) else 0 end)
    }' "$COST_TRACKING_FILE"
}

# Estimate remaining budget
get_remaining_budget() {
    local budget="${1:-10.00}"
    local current=$(get_total_cost)
    local remaining=$(echo "scale=6; $budget - $current" | bc)

    echo "$remaining"
}

# Project total cost based on completed stories
project_total_cost() {
    local total_stories="${1:-1}"

    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "0"
        return
    fi

    local completed=$(jq '.stories | length' "$COST_TRACKING_FILE")
    local current_cost=$(get_total_cost)

    if (( completed == 0 )); then
        echo "0"
        return
    fi

    local avg_cost=$(echo "scale=6; $current_cost / $completed" | bc)
    local projected=$(echo "scale=6; $avg_cost * $total_stories" | bc)

    echo "$projected"
}

# Reset cost tracking
reset_cost_tracking() {
    local feature="${1:-default}"

    if [[ -n "$COST_TRACKING_FILE" ]] && [[ -f "$COST_TRACKING_FILE" ]]; then
        rm -f "$COST_TRACKING_FILE"
    fi

    TOTAL_INPUT_TOKENS=0
    TOTAL_OUTPUT_TOKENS=0
    TOTAL_COST_USD=0

    init_cost_tracking "$feature"
}

# Export cost data
export_cost_data() {
    local output_file="${1:-cost-export.json}"

    if [[ -z "$COST_TRACKING_FILE" ]] || [[ ! -f "$COST_TRACKING_FILE" ]]; then
        echo "No cost data to export" >&2
        return 1
    fi

    cp "$COST_TRACKING_FILE" "$output_file"
    echo "Cost data exported to: $output_file"
}

# Print model pricing reference
print_pricing_reference() {
    cat << EOF
╔═══════════════════════════════════════════════════════════╗
║              Claude Model Pricing Reference               ║
╠═══════════════════════════════════════════════════════════╣
║  Model    │  Input/1K tokens  │  Output/1K tokens        ║
╠═══════════════════════════════════════════════════════════╣
║  Opus     │     \$0.015        │     \$0.075              ║
║  Sonnet   │     \$0.003        │     \$0.015              ║
║  Haiku    │     \$0.00025      │     \$0.00125            ║
╚═══════════════════════════════════════════════════════════╝
EOF
}
