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
WORKFLOW_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$(dirname "$WORKFLOW_DIR")")"
CURRENT_TASK="$WORKFLOW_DIR/prompts/CURRENT_TASK.md"
LOG_FILE="$WORKFLOW_DIR/ralph-orchestrator.log"
MAX_ITERATIONS_PER_STORY=${MAX_ITERATIONS:-50}

# Parse arguments - default to looking for any JSON in stories/
STORIES_FILE="${1:-}"
if [[ -z "$STORIES_FILE" ]]; then
    STORIES_FILE=$(ls "$WORKFLOW_DIR/stories/"*.json 2>/dev/null | head -1)
fi

if [[ -z "$STORIES_FILE" ]]; then
    echo "❌ No stories file found. Create one at .claude/ralph-workflow/stories/[feature].json"
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
    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║           Ralph Wiggum Orchestrator v2.0                  ║${NC}"
    log "${BLUE}║           Fresh Context Per Iteration                     ║${NC}"
    log "${BLUE}╠═══════════════════════════════════════════════════════════╣${NC}"
    log "${BLUE}║ Stories: ${CYAN}$stories_name${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
}

get_total_stories() {
    jq '.user_stories | length' "$STORIES_FILE"
}

get_completed_count() {
    jq '[.user_stories[] | select(.status == "completed")] | length' "$STORIES_FILE"
}

get_next_incomplete_story() {
    jq -r '.user_stories[] | select(.status != "completed") | .id' "$STORIES_FILE" | head -1
}

get_story_by_id() {
    local story_id=$1
    jq -r ".user_stories[] | select(.id == \"$story_id\")" "$STORIES_FILE"
}

get_story_position() {
    local story_id=$1
    jq -r ".user_stories | to_entries | map(select(.value.id == \"$story_id\")) | .[0].key + 1" "$STORIES_FILE"
}

mark_story_completed() {
    local story_id=$1
    log "${YELLOW}Marking $story_id as completed...${NC}"

    local tmp_file=$(mktemp)
    jq "(.user_stories[] | select(.id == \"$story_id\") | .status) = \"completed\"" "$STORIES_FILE" > "$tmp_file"
    mv "$tmp_file" "$STORIES_FILE"

    log "${GREEN}✓ $story_id marked as completed${NC}"
}

get_next_story() {
    local current=$1
    jq -r "
        .user_stories as \$stories |
        (\$stories | to_entries | map(select(.value.id == \"$current\")) | .[0].key) as \$idx |
        if \$idx != null and (\$idx + 1) < (\$stories | length) then
            \$stories[\$idx + 1].id
        else
            \"\"
        end
    " "$STORIES_FILE"
}

generate_task_file() {
    local story_id=$1
    log "${YELLOW}Generating CURRENT_TASK.md for $story_id...${NC}"

    local story_data=$(jq -r ".user_stories[] | select(.id == \"$story_id\")" "$STORIES_FILE")
    local title=$(echo "$story_data" | jq -r '.title')
    local role=$(echo "$story_data" | jq -r '.user_story.role')
    local goal=$(echo "$story_data" | jq -r '.user_story.goal')
    local benefit=$(echo "$story_data" | jq -r '.user_story.benefit')
    local prompt=$(echo "$story_data" | jq -r '.prompt')
    local completion_promise=$(echo "$story_data" | jq -r '.completion_promise')
    local story_num=$(get_story_position "$story_id")
    local total=$(get_total_stories)

    cat > "$CURRENT_TASK" << EOF
# Current Ralph Task: $story_id - $title

## Story $story_num of $total

---

## User Story
**As a** $role,
**I want** $goal,
**So that** $benefit.

---

$prompt

---

## Completion Promise

When ALL success criteria are met and all tests pass, output:

<promise>$completion_promise</promise>

---
EOF

    log "${GREEN}✓ Generated task file for $story_id${NC}"
}

commit_progress() {
    local current_story=$1
    local next_story=$2

    log "${YELLOW}Committing progress...${NC}"
    git add -A
    git commit -m "Complete $current_story, advance to $next_story

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null || log "${YELLOW}Nothing to commit${NC}"
}

clear_session_context() {
    local story_id=$1
    log "${YELLOW}Clearing session context...${NC}"
    rm -f .claude/ralph-loop.local.md 2>/dev/null
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

    log ""
    log "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    log "${GREEN}  Starting Ralph Loop for: $story_id${NC}"
    log "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    log ""

    clear_session_context "$story_id"
    generate_task_file "$story_id"

    while [ $iteration -lt $MAX_ITERATIONS_PER_STORY ]; do
        iteration=$((iteration + 1))
        log "${BLUE}─── Iteration $iteration of $MAX_ITERATIONS_PER_STORY ───${NC}"

        run_ralph_iteration "$output_file"

        if check_completion "$output_file"; then
            log ""
            log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
            log "${GREEN}║     ✓ $story_id COMPLETED (iteration $iteration)          ${NC}"
            log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

            mark_story_completed "$story_id"
            rm -f "$output_file"
            return 0
        fi

        log "${YELLOW}Completion promise not found. Continuing...${NC}"
        sleep 2
    done

    log "${RED}⚠️ Max iterations reached without completion${NC}"
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
                  Default: First .json file in .claude/ralph-workflow/stories/

ENVIRONMENT:
  MAX_ITERATIONS  Max iterations per story (default: 50)

EXAMPLES:
  $0
  $0 .claude/ralph-workflow/stories/my-feature.json
  MAX_ITERATIONS=30 $0
EOF
}

main() {
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_usage
        exit 0
    fi

    banner
    check_dependencies
    run_all_stories
}

main "$@"
