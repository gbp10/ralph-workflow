#!/bin/bash
# run-lint.sh
# PostToolUse hook script for UI layer agent
# Runs ESLint after file modifications

set -euo pipefail

# Get project directory from Claude environment
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Change to project directory
cd "$PROJECT_DIR"

# Run ESLint
if npm run lint 2>&1; then
  echo "Lint check passed"
  exit 0
else
  echo "Lint errors detected" >&2
  exit 2  # Exit code 2 = blocking error, stderr fed to Claude
fi
