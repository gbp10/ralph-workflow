#!/bin/bash
# run-typecheck.sh
# PostToolUse hook script for data/service/api layer agents
# Runs TypeScript type checking after file modifications

set -euo pipefail

# Get project directory from Claude environment
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Change to project directory
cd "$PROJECT_DIR"

# Run TypeScript type check
if npx tsc --noEmit 2>&1; then
  echo "TypeScript check passed"
  exit 0
else
  echo "TypeScript errors detected" >&2
  exit 2  # Exit code 2 = blocking error, stderr fed to Claude
fi
