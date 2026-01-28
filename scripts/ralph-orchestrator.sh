#!/bin/bash
# Ralph Wiggum Orchestrator
# Runs through ALL stories in a JSON file until complete
#
# Usage:
#   ./ralph-orchestrator.sh [STORIES_FILE]
#
# Flow:
# 1. Load stories from JSON file
# 2. Find first incomplete story
# 3. Generate CURRENT_TASK.md for that story
# 4. Run Ralph loop until completion promise detected
# 5. Mark story complete, advance to next
# 6. Clear context (each --print invocation is already fresh)
# 7. Repeat until ALL stories done

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(pwd)"
RALPH_DIR="$PROJECT_DIR/ralph"
CURRENT_TASK="$RALPH_DIR/state/current-task.md"
LOG_FILE="$RALPH_DIR/state/orchestrator.log"
MAX_ITERATIONS_PER_STORY=${MAX_ITERATIONS:-50}
BUDGET_LIMIT=${BUDGET_LIMIT:-10.00}
USE_LAYER_AGENTS=${USE_LAYER_AGENTS:-true}  # Set to false to disable layer agent delegation

# Source checkpoint library
source "$SCRIPT_DIR/lib/checkpoint.sh" 2>/dev/null || {
    echo "Warning: checkpoint.sh not found, running without checkpoint support"
    CHECKPOINT_ENABLED=false
}
CHECKPOINT_ENABLED=${CHECKPOINT_ENABLED:-true}

# Source structured logger
source "$SCRIPT_DIR/lib/logger.sh" 2>/dev/null || {
    echo "Warning: logger.sh not found, running without structured logging"
    STRUCTURED_LOGGING=false
}
STRUCTURED_LOGGING=${STRUCTURED_LOGGING:-true}

# Source cost tracking
source "$SCRIPT_DIR/lib/cost.sh" 2>/dev/null || {
    echo "Warning: cost.sh not found, running without cost tracking"
    COST_TRACKING=false
}
COST_TRACKING=${COST_TRACKING:-true}

# Parse arguments - default to looking for any JSON in stories/
STORIES_FILE="${1:-}"

if [[ -z "$STORIES_FILE" ]]; then
    # No argument - find first stories.json in specs/
    STORIES_FILE=$(ls "$RALPH_DIR/specs/"*/stories.json 2>/dev/null | head -1)
elif [[ ! "$STORIES_FILE" == *"/"* ]] && [[ ! "$STORIES_FILE" == *.json ]]; then
    # Just a feature name (no slashes, no .json) - look in specs directory
    STORIES_FILE="$RALPH_DIR/specs/${STORIES_FILE}/stories.json"
fi

if [[ -z "$STORIES_FILE" ]]; then
    echo "❌ No stories file found. Create one at ralph/specs/[feature]/stories.json"
    echo "   Or run /solution-to-stories first to generate stories from a blueprint."
    exit 1
fi

# Resolve relative path
if [[ ! "$STORIES_FILE" = /* ]]; then
    STORIES_FILE="$PROJECT_DIR/$STORIES_FILE"
fi

cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

banner() {
    local stories_name=$(basename "$STORIES_FILE" .json)
    local agent_mode="Direct Execution"
    [[ "$USE_LAYER_AGENTS" == "true" ]] && agent_mode="Layer Agent Delegation"

    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║           Ralph Wiggum Orchestrator v2.1                  ║${NC}"
    log "${BLUE}║           $agent_mode                      ${NC}"
    log "${BLUE}╠═══════════════════════════════════════════════════════════╣${NC}"
    log "${BLUE}║ Stories: ${CYAN}$stories_name${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

get_total_stories() {
    jq '.stories | length' "$STORIES_FILE"
}

get_completed_count() {
    # Handle stories that may not have status field yet (treat missing as "pending")
    jq '[.stories[] | select(.status == "completed")] | length' "$STORIES_FILE"
}

get_next_incomplete_story() {
    # Stories without status field are considered incomplete
    jq -r '.stories[] | select(.status != "completed") | .id' "$STORIES_FILE" | head -1
}

get_story_by_id() {
    local story_id=$1
    jq -r ".stories[] | select(.id == \"$story_id\")" "$STORIES_FILE"
}

get_story_position() {
    local story_id=$1
    jq -r ".stories | to_entries | map(select(.value.id == \"$story_id\")) | .[0].key + 1" "$STORIES_FILE"
}

mark_story_completed() {
    local story_id=$1
    log "${YELLOW}Marking $story_id as completed...${NC}"

    local tmp_file=$(mktemp)
    # Add or update the status field
    jq "(.stories |= map(if .id == \"$story_id\" then . + {\"status\": \"completed\"} else . end))" "$STORIES_FILE" > "$tmp_file"
    mv "$tmp_file" "$STORIES_FILE"

    log "${GREEN}✓ $story_id marked as completed${NC}"
}

get_next_story() {
    local current=$1
    jq -r "
        .stories as \$stories |
        (\$stories | to_entries | map(select(.value.id == \"$current\")) | .[0].key) as \$idx |
        if \$idx != null and (\$idx + 1) < (\$stories | length) then
            \$stories[\$idx + 1].id
        else
            \"\"
        end
    " "$STORIES_FILE"
}

get_layer_agent() {
    local layer=$1
    case "$layer" in
        data)    echo "ralph-workflow:ralph-data-layer" ;;
        service) echo "ralph-workflow:ralph-service-layer" ;;
        api)     echo "ralph-workflow:ralph-api-layer" ;;
        ui)      echo "ralph-workflow:ralph-ui-layer" ;;
        *)       echo "" ;;  # No agent for unknown layers
    esac
}

generate_task_file() {
    local story_id=$1
    log "${YELLOW}Generating CURRENT_TASK.md for $story_id...${NC}"

    # Ensure prompts directory exists
    mkdir -p "$(dirname "$CURRENT_TASK")"

    local story_data=$(jq -r ".stories[] | select(.id == \"$story_id\")" "$STORIES_FILE")
    local title=$(echo "$story_data" | jq -r '.title')
    local user_story=$(echo "$story_data" | jq -r '.userStory')
    local layer=$(echo "$story_data" | jq -r '.layer')
    local priority=$(echo "$story_data" | jq -r '.priority')
    local story_num=$(get_story_position "$story_id")
    local total=$(get_total_stories)

    # Get the appropriate layer agent
    local layer_agent=$(get_layer_agent "$layer")

    # Extract acceptance criteria as formatted text
    local acceptance_criteria=$(echo "$story_data" | jq -r '
        .acceptanceCriteria | map(
            "### " + .scenario + "\n" +
            "**Given** " + .given + "\n" +
            "**When** " + .when + "\n" +
            "**Then** " + .then + "\n"
        ) | join("\n")
    ')

    # Extract constraints
    local constraints=$(echo "$story_data" | jq -r '.constraints | join(", ")')

    # Extract files to create/modify
    local files=$(echo "$story_data" | jq -r '
        .files | map("- [" + .action + "] `" + .path + "`") | join("\n")
    ')

    # Extract dependencies
    local dependencies=$(echo "$story_data" | jq -r '
        if .dependencies | length > 0 then
            .dependencies | join(", ")
        else
            "None"
        end
    ')

    # Get global constraints from the file if available
    local global_constraints=$(jq -r '
        if .globalConstraints then
            .globalConstraints | to_entries | map(
                "**" + .key + ":**\n" +
                (.value | map("- " + .id + ": " + .rule) | join("\n"))
            ) | join("\n\n")
        else
            ""
        end
    ' "$STORIES_FILE")

    # Build the task content that will be passed to the agent
    local task_content="# Story: $story_id - $title

## Story $story_num of $total | Layer: $layer | Priority: $priority

## User Story
$user_story

## Acceptance Criteria
$acceptance_criteria

## Files to Create/Modify
$files

## Constraints
Applicable constraints: $constraints

## Global Constraints Reference
$global_constraints

## Dependencies
$dependencies

## Instructions
**CRITICAL: This is an AUTONOMOUS execution. DO NOT ask questions - make reasonable decisions and proceed.**

1. Read and understand the user story and acceptance criteria
2. Check dependencies are satisfied before starting
3. Create/modify the files listed above
4. Ensure ALL acceptance criteria pass
5. Follow the applicable constraints strictly
6. When facing design choices, pick the most pragmatic option and document your decision
7. If something is ambiguous, make a reasonable assumption and note it in your summary

**DO NOT:**
- Ask clarifying questions (this is non-interactive)
- Wait for user input
- Present options and ask which to choose

**DO:**
- Make autonomous decisions
- Document assumptions in your completion summary
- Proceed directly to implementation

## Completion
When ALL acceptance criteria are met and the implementation is complete, output:
<promise>$story_id COMPLETE</promise>"

    # Generate the orchestration prompt based on whether we have a layer agent
    if [[ -n "$layer_agent" ]] && [[ "$USE_LAYER_AGENTS" != "false" ]]; then
        # USE LAYER AGENT via Task tool
        log "${CYAN}  → Will delegate to layer agent: $layer_agent${NC}"
        cat > "$CURRENT_TASK" << EOF
# Ralph Orchestrator Task: Execute $story_id via Layer Agent

You MUST use the Task tool to delegate this story to the specialized layer agent.

## Agent Delegation Instructions

**IMMEDIATELY** invoke the Task tool with these EXACT parameters:

\`\`\`
Tool: Task
Parameters:
  - description: "Execute $story_id ($layer layer)"
  - subagent_type: "$layer_agent"
  - prompt: (the full task content below)
\`\`\`

## Task Content to Pass to Agent

$task_content

---

## CRITICAL INSTRUCTIONS

1. **DO NOT** attempt to implement this yourself
2. **DO** use the Task tool to delegate to \`$layer_agent\`
3. **WAIT** for the agent to complete
4. **VERIFY** the agent outputs \`<promise>$story_id COMPLETE</promise>\`
5. **RELAY** the completion promise in your response

When the layer agent completes successfully, output:

<promise>$story_id COMPLETE</promise>

---
EOF
    else
        # DIRECT EXECUTION (no layer agent)
        log "${YELLOW}  → Direct execution (no layer agent for layer: $layer)${NC}"
        cat > "$CURRENT_TASK" << EOF
$task_content

---

## Completion Promise

When ALL acceptance criteria are met and the implementation is complete, output:

<promise>$story_id COMPLETE</promise>

---
EOF
    fi

    log "${GREEN}✓ Generated task file for $story_id${NC}"
}

commit_progress() {
    local current_story=$1
    local next_story=$2

    # Only commit if we're in a git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log "${YELLOW}Committing progress...${NC}"
        git add -A
        git commit -m "Complete $current_story, advance to $next_story

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null || log "${YELLOW}Nothing to commit${NC}"
    else
        log "${YELLOW}Skipping git commit (not a git repository)${NC}"
    fi
}

clear_session_context() {
    local story_id=$1
    log "${YELLOW}Clearing session context...${NC}"
    rm -f ralph/state/loop.local.md 2>/dev/null
    rm -f /tmp/ralph-*.tmp 2>/dev/null
    log "${GREEN}✓ Context cleared${NC}"
}

run_ralph_iteration() {
    local output_file=$1
    # Run Claude with full permissions
    # --print: Non-interactive, fresh context per call
    # Adjust flags based on your needs
    claude --dangerously-skip-permissions --print < "$CURRENT_TASK" 2>&1 | tee -a "$output_file"
}

check_completion() {
    local output_file=$1
    grep -q "<promise>.*COMPLETE</promise>" "$output_file"
}

run_story_loop() {
    local story_id=$1
    local iteration=0
    local output_file=$(mktemp)

    # Check if story already completed (checkpoint resume)
    if [[ "$CHECKPOINT_ENABLED" == "true" ]]; then
        if [[ "$(should_skip_story "$story_id")" == "true" ]]; then
            log "${YELLOW}⏭ Skipping $story_id (already completed in checkpoint)${NC}"
            return 0
        fi

        # Check budget before starting
        if ! check_budget; then
            log "${RED}⚠️ Budget exceeded - stopping execution${NC}"
            return 2
        fi

        # Mark story as in_progress
        start_story "$story_id"
    fi

    log ""
    log "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    log "${GREEN}  Starting Ralph Loop for: $story_id${NC}"
    log "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    log ""

    # Structured logging: story start
    if [[ "$STRUCTURED_LOGGING" == "true" ]]; then
        local story_data=$(get_story_by_id "$story_id")
        local layer=$(echo "$story_data" | jq -r '.layer // "unknown"')
        local priority=$(echo "$story_data" | jq -r '.priority // "unknown"')
        log_story_start "$story_id" "$layer" "$priority"
    fi

    local start_time=$(date +%s%3N 2>/dev/null || date +%s)

    clear_session_context "$story_id"
    generate_task_file "$story_id"

    while [ $iteration -lt $MAX_ITERATIONS_PER_STORY ]; do
        iteration=$((iteration + 1))
        log "${BLUE}─── Iteration $iteration of $MAX_ITERATIONS_PER_STORY ───${NC}"

        # Structured logging: iteration start
        [[ "$STRUCTURED_LOGGING" == "true" ]] && log_iteration_start "$iteration"

        run_ralph_iteration "$output_file"

        if check_completion "$output_file"; then
            log ""
            log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
            log "${GREEN}║     ✓ $story_id COMPLETED (iteration $iteration)          ${NC}"
            log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

            mark_story_completed "$story_id"

            # Calculate duration
            local end_time=$(date +%s%3N 2>/dev/null || date +%s)
            local duration_ms=$((end_time - start_time))

            # Save to checkpoint with iteration count
            if [[ "$CHECKPOINT_ENABLED" == "true" ]]; then
                complete_story "$story_id" "$iteration" 0
            fi

            # Structured logging: story complete
            if [[ "$STRUCTURED_LOGGING" == "true" ]]; then
                log_story_complete "$story_id" "$iteration" "$duration_ms" 0
            fi

            rm -f "$output_file"
            return 0
        fi

        log "${YELLOW}Completion promise not found. Continuing...${NC}"
        sleep 2
    done

    log "${RED}⚠️ Max iterations reached without completion${NC}"

    # Mark as failed in checkpoint
    if [[ "$CHECKPOINT_ENABLED" == "true" ]]; then
        fail_story "$story_id" "$iteration" 0
    fi

    # Structured logging: story failed
    if [[ "$STRUCTURED_LOGGING" == "true" ]]; then
        log_story_failed "$story_id" "$iteration" "max_iterations_exceeded"
    fi

    rm -f "$output_file"
    return 1
}

run_all_stories() {
    local total=$(get_total_stories)
    local completed=$(get_completed_count)

    log ""
    log "${CYAN}Progress: $completed / $total stories completed${NC}"
    log ""

    while true; do
        local next_story=$(get_next_incomplete_story)

        if [ -z "$next_story" ]; then
            log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
            log "${GREEN}║     🎉 ALL $total STORIES COMPLETE!                       ${NC}"
            log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

            # Show cost summary
            if [[ "$COST_TRACKING" == "true" ]]; then
                get_cost_breakdown
            fi

            return 0
        fi

        log "${CYAN}Next story: $next_story${NC}"

        if run_story_loop "$next_story"; then
            completed=$(get_completed_count)

            if [ "$completed" -lt "$total" ]; then
                local next_incomplete=$(get_next_incomplete_story)
                commit_progress "$next_story" "$next_incomplete"
                clear_session_context "$next_incomplete"
            else
                commit_progress "$next_story" "DONE"
                return 0
            fi
        else
            log "${RED}Story $next_story did not complete. Manual intervention needed.${NC}"
            return 1
        fi
    done
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log "${RED}Error: jq is required. Install with: brew install jq${NC}"
        exit 1
    fi

    if ! command -v claude &> /dev/null; then
        log "${RED}Error: claude CLI is required${NC}"
        exit 1
    fi

    if [ ! -f "$STORIES_FILE" ]; then
        log "${RED}Error: Stories file not found: $STORIES_FILE${NC}"
        exit 1
    fi
}

show_usage() {
    cat << EOF
Ralph Wiggum Orchestrator - Automated Story Execution

USAGE:
  $0 [STORIES_FILE]

ARGUMENTS:
  STORIES_FILE    Path to JSON file containing user stories
                  Default: First stories.json in ralph/specs/

ENVIRONMENT:
  MAX_ITERATIONS      Max iterations per story (default: 50)
  BUDGET_LIMIT        Max cost in USD before stopping (default: 10.00)
  USE_LAYER_AGENTS    Delegate to layer-specialized agents (default: true)
  CHECKPOINT_ENABLED  Enable checkpoint/resume (default: true)
  STRUCTURED_LOGGING  Enable JSON logging (default: true)
  COST_TRACKING       Enable cost tracking (default: true)
  LOG_LEVEL           Log level: DEBUG, INFO, WARN, ERROR (default: INFO)

LAYER AGENTS:
  When USE_LAYER_AGENTS=true (default), stories are delegated to specialized agents:
    - data layer    → ralph-workflow:ralph-data-layer
    - service layer → ralph-workflow:ralph-service-layer
    - api layer     → ralph-workflow:ralph-api-layer
    - ui layer      → ralph-workflow:ralph-ui-layer

  Each agent has focused context for its architectural layer, improving quality.

OUTPUT LOCATIONS:
  Stories:     ralph/specs/[feature]/stories.json
  Task file:   ralph/state/current-task.md
  Log file:    ralph/state/orchestrator.log
  Checkpoint:  ralph/state/checkpoint-[feature].json
  Cost data:   ralph/state/cost-[feature].json
  JSON logs:   ralph/logs/[feature]-YYYYMMDD.jsonl

CHECKPOINT/RESUME:
  The orchestrator automatically saves progress after each story.
  If interrupted, simply re-run with the same stories file to resume.

  Checkpoint tracks:
    - Story completion status
    - Iteration counts
    - Cost accumulation
    - Budget enforcement

EXAMPLES:
  $0
  $0 ralph/specs/my-feature/stories.json
  MAX_ITERATIONS=30 $0
  BUDGET_LIMIT=5.00 $0
  CHECKPOINT_ENABLED=false $0  # Disable checkpointing
EOF
}

main() {
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_usage
        exit 0
    fi

    banner
    check_dependencies

    # Extract feature name
    local feature_name=$(basename "$(dirname "$STORIES_FILE")")

    # Initialize structured logging
    if [[ "$STRUCTURED_LOGGING" == "true" ]]; then
        init_logger "$feature_name"
        log_info "Orchestrator started" "{\"stories_file\": \"$STORIES_FILE\", \"max_iterations\": $MAX_ITERATIONS_PER_STORY}"
    fi

    # Initialize cost tracking
    if [[ "$COST_TRACKING" == "true" ]]; then
        init_cost_tracking "$feature_name"
        log "${CYAN}Cost tracking enabled (budget: \$$BUDGET_LIMIT)${NC}"
    fi

    # Initialize checkpoint system
    if [[ "$CHECKPOINT_ENABLED" == "true" ]]; then
        init_checkpoint "$feature_name" "$BUDGET_LIMIT"
        log "${CYAN}Checkpoint initialized for: $feature_name${NC}"
        get_checkpoint_summary
    fi

    run_all_stories
}

main "$@"
