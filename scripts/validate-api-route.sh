#!/bin/bash
# validate-api-route.sh
# PreToolUse hook script for API layer agent
# Validates API route files before writing

set -euo pipefail

# Get the file path from the tool arguments
# Claude passes tool arguments as JSON in $ARGUMENTS
FILE_PATH=$(echo "$ARGUMENTS" | jq -r '.file_path // empty' 2>/dev/null || echo "")

# If no file path, allow the operation
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Check if this is an API route file
if [[ "$FILE_PATH" == *"/api/"* && "$FILE_PATH" == *"route.ts"* ]]; then
  echo "Validating API route: $FILE_PATH"

  # Check for common API route issues in the content being written
  CONTENT=$(echo "$ARGUMENTS" | jq -r '.content // empty' 2>/dev/null || echo "")

  if [[ -n "$CONTENT" ]]; then
    # Warning: Missing Zod validation
    if [[ "$CONTENT" == *"request.json()"* ]] && [[ "$CONTENT" != *"safeParse"* ]]; then
      echo "Warning: API route may be missing Zod validation" >&2
    fi

    # Warning: Missing error handling
    if [[ "$CONTENT" != *"catch"* ]]; then
      echo "Warning: API route may be missing error handling" >&2
    fi
  fi
fi

# Allow the operation to proceed
exit 0
