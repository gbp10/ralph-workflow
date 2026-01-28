#!/bin/bash
# logger.sh - Structured JSON Logging for Ralph Orchestrator
#
# Provides structured logging with JSON output for debugging and analysis.
# Logs are written to ralph/logs/ with daily rotation.
#
# Usage:
#   source logger.sh
#   init_logger "feature-name"
#   log_info "Story started" '{"story_id": "STORY-001"}'
#   log_error "Build failed" '{"exit_code": 1}'

# NOTE: Do not set shell options here — let the parent script control them.
# macOS ships bash 3.2 which does not support declare -A (associative arrays).

# Directory for log files
LOG_DIR="${RALPH_DIR:-$(pwd)/ralph}/logs"
# Don't overwrite LOG_FILE if already set by parent
LOG_FILE="${LOG_FILE:-}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Log level lookup (bash 3.2 compatible — no associative arrays)
_log_level_num() {
    case "${1:-INFO}" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        FATAL) echo 4 ;;
        *)     echo 1 ;;
    esac
}

# Current context (set by caller)
export CURRENT_COMPONENT="${CURRENT_COMPONENT:-orchestrator}"
export CURRENT_STORY_ID="${CURRENT_STORY_ID:-}"
export CURRENT_ITERATION="${CURRENT_ITERATION:-0}"

# Initialize logger for a feature
init_logger() {
    local feature="${1:-default}"

    mkdir -p "$LOG_DIR"

    # Create daily log file
    local date_stamp=$(date +%Y%m%d)
    LOG_FILE="$LOG_DIR/${feature}-${date_stamp}.jsonl"

    # Log initialization
    _write_log "INFO" "Logger initialized" "{\"feature\": \"$feature\", \"log_file\": \"$LOG_FILE\"}"

    export LOG_FILE
}

# Get current log file path
get_log_file() {
    echo "$LOG_FILE"
}

# Internal: Write structured log entry
_write_log() {
    local level="$1"
    local message="$2"
    local extra="${3:-{}}"

    # Check log level threshold (bash 3.2 compatible)
    local level_num=$(_log_level_num "$level")
    local threshold_num=$(_log_level_num "$LOG_LEVEL")

    if (( level_num < threshold_num )); then
        return 0
    fi

    # Generate timestamp with milliseconds
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

    # Build JSON log entry
    local log_entry=$(jq -cn \
        --arg ts "$timestamp" \
        --arg lvl "$level" \
        --arg comp "$CURRENT_COMPONENT" \
        --arg sid "${CURRENT_STORY_ID:-}" \
        --argjson iter "${CURRENT_ITERATION:-0}" \
        --arg msg "$message" \
        --argjson extra "$extra" \
        '{
            timestamp: $ts,
            level: $lvl,
            component: $comp,
            story_id: (if $sid == "" then null else $sid end),
            iteration: $iter,
            message: $msg
        } + $extra'
    )

    # Write to log file if initialized
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi

    # Also output to stderr for real-time visibility (in debug mode)
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        echo "$log_entry" >&2
    fi
}

# Log functions by level
log_debug() {
    local message="$1"
    local extra="${2:-{}}"
    _write_log "DEBUG" "$message" "$extra"
}

log_info() {
    local message="$1"
    local extra="${2:-{}}"
    _write_log "INFO" "$message" "$extra"
}

log_warn() {
    local message="$1"
    local extra="${2:-{}}"
    _write_log "WARN" "$message" "$extra"
}

log_error() {
    local message="$1"
    local extra="${2:-{}}"
    _write_log "ERROR" "$message" "$extra"
}

log_fatal() {
    local message="$1"
    local extra="${2:-{}}"
    _write_log "FATAL" "$message" "$extra"
}

# Log story lifecycle events
log_story_start() {
    local story_id="$1"
    local layer="${2:-unknown}"
    local priority="${3:-unknown}"

    export CURRENT_STORY_ID="$story_id"
    export CURRENT_ITERATION=0

    log_info "Story started" "$(jq -cn \
        --arg layer "$layer" \
        --arg priority "$priority" \
        '{event: "story_start", layer: $layer, priority: $priority}'
    )"
}

log_story_complete() {
    local story_id="$1"
    local iterations="$2"
    local duration_ms="${3:-0}"
    local cost_usd="${4:-0}"

    log_info "Story completed" "$(jq -cn \
        --argjson iter "$iterations" \
        --argjson dur "$duration_ms" \
        --argjson cost "$cost_usd" \
        '{event: "story_complete", iterations: $iter, duration_ms: $dur, cost_usd: $cost}'
    )"

    export CURRENT_STORY_ID=""
    export CURRENT_ITERATION=0
}

log_story_failed() {
    local story_id="$1"
    local iterations="$2"
    local reason="${3:-unknown}"

    log_error "Story failed" "$(jq -cn \
        --argjson iter "$iterations" \
        --arg reason "$reason" \
        '{event: "story_failed", iterations: $iter, reason: $reason}'
    )"
}

# Log iteration events
log_iteration_start() {
    local iteration="$1"
    export CURRENT_ITERATION="$iteration"

    log_debug "Iteration started" "$(jq -cn '{event: "iteration_start"}')"
}

log_iteration_complete() {
    local iteration="$1"
    local duration_ms="${2:-0}"
    local tokens_input="${3:-0}"
    local tokens_output="${4:-0}"

    log_debug "Iteration completed" "$(jq -cn \
        --argjson dur "$duration_ms" \
        --argjson tin "$tokens_input" \
        --argjson tout "$tokens_output" \
        '{event: "iteration_complete", duration_ms: $dur, tokens: {input: $tin, output: $tout}}'
    )"
}

# Log tool usage (for PostToolUse hooks)
log_tool_use() {
    local tool_name="$1"
    local file_path="${2:-}"
    local duration_ms="${3:-0}"
    local success="${4:-true}"

    log_debug "Tool used" "$(jq -cn \
        --arg tool "$tool_name" \
        --arg file "$file_path" \
        --argjson dur "$duration_ms" \
        --argjson success "$success" \
        '{event: "tool_use", tool: $tool, file: (if $file == "" then null else $file end), duration_ms: $dur, success: $success}'
    )"
}

# Log quality gate results
log_quality_gate() {
    local gate_name="$1"
    local passed="$2"
    local details="${3:-{}}"

    local level="INFO"
    [[ "$passed" == "false" ]] && level="WARN"

    _write_log "$level" "Quality gate: $gate_name" "$(jq -cn \
        --arg name "$gate_name" \
        --argjson passed "$passed" \
        --argjson details "$details" \
        '{event: "quality_gate", gate: $name, passed: $passed, details: $details}'
    )"
}

# Get logs for a specific story
get_story_logs() {
    local story_id="$1"

    if [[ -z "$LOG_FILE" ]] || [[ ! -f "$LOG_FILE" ]]; then
        echo "[]"
        return
    fi

    jq -c "select(.story_id == \"$story_id\")" "$LOG_FILE"
}

# Get logs for a specific level
get_logs_by_level() {
    local level="$1"

    if [[ -z "$LOG_FILE" ]] || [[ ! -f "$LOG_FILE" ]]; then
        echo "[]"
        return
    fi

    jq -c "select(.level == \"$level\")" "$LOG_FILE"
}

# Get log summary
get_log_summary() {
    if [[ -z "$LOG_FILE" ]] || [[ ! -f "$LOG_FILE" ]]; then
        echo "No logs available"
        return
    fi

    local total=$(wc -l < "$LOG_FILE")
    local errors=$(grep -c '"level":"ERROR"' "$LOG_FILE" 2>/dev/null || echo 0)
    local warns=$(grep -c '"level":"WARN"' "$LOG_FILE" 2>/dev/null || echo 0)

    cat << EOF
Log Summary: $LOG_FILE
────────────────────────────────────────
Total entries: $total
Errors:        $errors
Warnings:      $warns
────────────────────────────────────────
EOF
}

# Rotate old log files (keep last N days)
rotate_logs() {
    local keep_days="${1:-7}"

    find "$LOG_DIR" -name "*.jsonl" -mtime +"$keep_days" -delete 2>/dev/null || true
    log_info "Log rotation complete" "$(jq -cn --argjson days "$keep_days" '{keep_days: $days}')"
}

# Export logs to a file
export_logs() {
    local output_file="${1:-logs-export.jsonl}"

    if [[ -z "$LOG_FILE" ]] || [[ ! -f "$LOG_FILE" ]]; then
        echo "No logs to export" >&2
        return 1
    fi

    cp "$LOG_FILE" "$output_file"
    echo "Logs exported to: $output_file"
}
