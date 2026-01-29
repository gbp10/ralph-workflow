#!/bin/bash
# Ralph Full Pipeline - End-to-End Autonomous Workflow
#
# Runs the complete pipeline from prompt/document to implemented feature:
#   /create-prd → /design-solution → /solution-to-stories → ralph-orchestrator
#
# Usage:
#   ./ralph-full-pipeline.sh "Feature description or path to requirements document"
#   ./ralph-full-pipeline.sh --feature-name "user-auth" "Add user authentication with JWT"
#   ./ralph-full-pipeline.sh --from-doc path/to/requirements.txt
#
# The script runs with --dangerously-skip-permissions for fully autonomous execution.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(pwd)"
RALPH_DIR="$PROJECT_DIR/.claude/ralph"
LOG_FILE="$RALPH_DIR/state/pipeline.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
FEATURE_NAME=""
FROM_DOC=""
PROMPT=""
SKIP_PHASES=""
MAX_ITERATIONS=${MAX_ITERATIONS:-50}

log() {
    echo -e "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

banner() {
    log ""
    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║         Ralph Full Pipeline - Autonomous Workflow         ║${NC}"
    log "${BLUE}║     /create-prd → /design-solution → /solution-to-stories ║${NC}"
    log "${BLUE}║                    → ralph-orchestrator                   ║${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    log ""
}

show_usage() {
    cat << EOF
Ralph Full Pipeline - End-to-End Autonomous Workflow

USAGE:
  $0 [OPTIONS] "Feature description"
  $0 --from-doc <path> [OPTIONS]

OPTIONS:
  --feature-name <name>   Feature name for output files (auto-generated if not provided)
  --from-doc <path>       Read feature description from file instead of argument
  --skip <phases>         Skip phases (comma-separated: prd,solution,stories,execute)
  --max-iterations <n>    Max iterations per story in orchestrator (default: 50)
  -h, --help              Show this help message

EXAMPLES:
  # From prompt
  $0 "Add user authentication with JWT tokens and refresh token flow"

  # With feature name
  $0 --feature-name "user-auth" "Add user authentication feature"

  # From document
  $0 --from-doc docs/features/auth-requirements.md

  # Skip to execution (if PRD and stories already exist)
  $0 --feature-name "user-auth" --skip prd,solution,stories

PHASES:
  1. /create-prd         - Generate PRD from feature description
  2. /design-solution    - Research codebase and create blueprint
  3. /solution-to-stories - Convert blueprint to user stories
  4. ralph-orchestrator  - Execute all stories autonomously

PERMISSIONS:
  All phases run with --dangerously-skip-permissions for autonomous execution.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --feature-name)
                FEATURE_NAME="$2"
                shift 2
                ;;
            --from-doc)
                FROM_DOC="$2"
                shift 2
                ;;
            --skip)
                SKIP_PHASES="$2"
                shift 2
                ;;
            --max-iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            *)
                PROMPT="$PROMPT $1"
                shift
                ;;
        esac
    done

    PROMPT=$(echo "$PROMPT" | xargs)  # Trim whitespace

    # Read from document if specified
    if [[ -n "$FROM_DOC" ]]; then
        if [[ ! -f "$FROM_DOC" ]]; then
            log "${RED}Error: Document not found: $FROM_DOC${NC}"
            exit 1
        fi
        PROMPT=$(cat "$FROM_DOC")
        # Extract feature name from filename if not provided
        if [[ -z "$FEATURE_NAME" ]]; then
            FEATURE_NAME=$(basename "$FROM_DOC" | sed 's/\.[^.]*$//' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
        fi
    fi

    if [[ -z "$PROMPT" ]]; then
        log "${RED}Error: No feature description provided${NC}"
        show_usage
        exit 1
    fi

    # Auto-generate feature name if not provided
    if [[ -z "$FEATURE_NAME" ]]; then
        FEATURE_NAME=$(echo "$PROMPT" | head -c 50 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    fi
}

should_skip() {
    local phase=$1
    echo "$SKIP_PHASES" | grep -qi "$phase"
}

check_dependencies() {
    log "${YELLOW}Checking dependencies...${NC}"

    if ! command -v claude &> /dev/null; then
        log "${RED}Error: claude CLI is required${NC}"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log "${RED}Error: jq is required. Install with: brew install jq${NC}"
        exit 1
    fi

    log "${GREEN}✓ All dependencies available${NC}"
}

phase_banner() {
    local phase_num=$1
    local phase_name=$2
    log ""
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${CYAN}  PHASE $phase_num: $phase_name${NC}"
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log ""
}

# Retry wrapper for Claude CLI calls.
# Retries up to MAX_RETRIES times with exponential backoff when
# claude --print returns "Error: No messages returned" or exits non-zero.
run_claude_with_retry() {
    local prompt="$1"
    local max_retries=${2:-3}
    local attempt=1
    local wait_secs=10

    while [[ $attempt -le $max_retries ]]; do
        local output
        local exit_code=0

        # Capture output and exit code
        output=$(echo "$prompt" | claude --dangerously-skip-permissions --print 2>&1) || exit_code=$?

        # Check for the known "No messages returned" error
        if echo "$output" | grep -q "Error: No messages returned"; then
            exit_code=1
        fi

        # Print output (always, so tee captures partial output)
        echo "$output" | tee -a "$LOG_FILE"

        if [[ $exit_code -eq 0 ]] && ! echo "$output" | grep -q "Error: No messages returned"; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            log "${YELLOW}⚠ Claude CLI returned error (attempt $attempt/$max_retries). Retrying in ${wait_secs}s...${NC}"
            sleep $wait_secs
            wait_secs=$((wait_secs * 2))
        else
            log "${RED}✗ Claude CLI failed after $max_retries attempts${NC}"
            return 1
        fi

        attempt=$((attempt + 1))
    done
}

run_phase_1_prd() {
    if should_skip "prd"; then
        log "${YELLOW}⏭ Skipping Phase 1: PRD Creation${NC}"
        return 0
    fi

    phase_banner 1 "PRD Creation (/create-prd)"

    local prd_prompt="Create a PRD for the following feature:

$PROMPT

Feature name: $FEATURE_NAME

Save the PRD to: .claude/ralph/specs/$FEATURE_NAME/requirements.md

Follow the /create-prd skill: research the codebase first, then write the PRD.

When complete, output: <promise>PRD COMPLETE</promise>"

    log "${YELLOW}Running Claude to create PRD...${NC}"
    run_claude_with_retry "$prd_prompt" 3

    # Verify PRD was created
    if [[ -f "$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/requirements.md" ]]; then
        log "${GREEN}✓ Phase 1 Complete: PRD created${NC}"
    else
        log "${RED}✗ Phase 1 Failed: PRD not found${NC}"
        exit 1
    fi
}

run_phase_2_solution() {
    if should_skip "solution"; then
        log "${YELLOW}⏭ Skipping Phase 2: Solution Design${NC}"
        return 0
    fi

    phase_banner 2 "Solution Design (/design-solution)"

    local solution_prompt="Design the implementation solution for the PRD at:
.claude/ralph/specs/$FEATURE_NAME/requirements.md

Follow the /design-solution skill:
1. Phase 1: Complete ALL 9 research areas (codebase patterns, architecture, database, API, dependencies, security, performance, prior art, UI/UX)
2. Phase 2: Synthesize findings (identify conflicts, document assumptions, consolidate constraints)
3. Phase 3: Create the Implementation Blueprint

Save outputs to:
- Research files: .claude/ralph/specs/$FEATURE_NAME/research/
- Synthesis: .claude/ralph/specs/$FEATURE_NAME/research-synthesis.md
- Blueprint: .claude/ralph/specs/$FEATURE_NAME/implementation-blueprint.md

When complete, output: <promise>BLUEPRINT COMPLETE</promise>"

    log "${YELLOW}Running Claude to design solution...${NC}"
    run_claude_with_retry "$solution_prompt" 3

    # Verify blueprint was created
    if [[ -f "$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/implementation-blueprint.md" ]]; then
        log "${GREEN}✓ Phase 2 Complete: Blueprint created${NC}"
    else
        log "${RED}✗ Phase 2 Failed: Blueprint not found${NC}"
        exit 1
    fi
}

run_phase_3_stories() {
    if should_skip "stories"; then
        log "${YELLOW}⏭ Skipping Phase 3: Story Conversion${NC}"
        return 0
    fi

    phase_banner 3 "Story Conversion (/solution-to-stories)"

    local stories_prompt="Convert the Implementation Blueprint to user stories.

Blueprint: .claude/ralph/specs/$FEATURE_NAME/implementation-blueprint.md

Follow the /solution-to-stories skill:
1. Validate blueprint has all required sections
2. Extract constraints and embed in stories
3. Create INVEST-validated stories with Gherkin acceptance criteria
4. Group stories by architectural layer (Data → Service → API → UI)
5. Estimate token budgets

Save to: .claude/ralph/specs/$FEATURE_NAME/stories.json

When complete, output: <promise>STORIES COMPLETE</promise>"

    log "${YELLOW}Running Claude to generate stories...${NC}"
    run_claude_with_retry "$stories_prompt" 3

    # Verify stories were created
    if [[ -f "$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/stories.json" ]]; then
        log "${GREEN}✓ Phase 3 Complete: Stories generated${NC}"
        # Validate JSON
        if jq . "$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/stories.json" > /dev/null 2>&1; then
            local story_count=$(jq '.stories | length' "$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/stories.json")
            log "${GREEN}  → $story_count user stories created${NC}"
        else
            log "${RED}  ⚠ Warning: Stories JSON may be invalid${NC}"
        fi
    else
        log "${RED}✗ Phase 3 Failed: Stories not found${NC}"
        exit 1
    fi
}

run_phase_4_execute() {
    if should_skip "execute"; then
        log "${YELLOW}⏭ Skipping Phase 4: Execution${NC}"
        return 0
    fi

    phase_banner 4 "Execution (ralph-orchestrator)"

    local stories_file="$PROJECT_DIR/.claude/ralph/specs/$FEATURE_NAME/stories.json"

    if [[ ! -f "$stories_file" ]]; then
        log "${RED}Error: Stories file not found: $stories_file${NC}"
        exit 1
    fi

    log "${YELLOW}Running Ralph Orchestrator...${NC}"
    log "${YELLOW}Max iterations per story: $MAX_ITERATIONS${NC}"
    log ""

    # Run the orchestrator
    MAX_ITERATIONS=$MAX_ITERATIONS "$SCRIPT_DIR/ralph-orchestrator.sh" "$stories_file"
}

summary() {
    log ""
    log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${GREEN}║              🎉 PIPELINE COMPLETE!                        ║${NC}"
    log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "${CYAN}Feature: $FEATURE_NAME${NC}"
    log ""
    log "${CYAN}Artifacts created:${NC}"
    log "  📄 PRD:       .claude/ralph/specs/$FEATURE_NAME/requirements.md"
    log "  🔬 Research:  .claude/ralph/specs/$FEATURE_NAME/research/"
    log "  📋 Blueprint: .claude/ralph/specs/$FEATURE_NAME/implementation-blueprint.md"
    log "  📝 Stories:   .claude/ralph/specs/$FEATURE_NAME/stories.json"
    log ""
    log "${CYAN}Log file: $LOG_FILE${NC}"
    log ""
}

main() {
    # Ensure ralph directories exist
    mkdir -p "$RALPH_DIR/specs" "$RALPH_DIR/state"

    parse_args "$@"
    banner
    check_dependencies

    log "${CYAN}Feature: $FEATURE_NAME${NC}"
    log "${CYAN}Description: $(echo "$PROMPT" | head -c 100)...${NC}"
    log ""

    run_phase_1_prd
    run_phase_2_solution
    run_phase_3_stories
    run_phase_4_execute

    summary
}

main "$@"
