---
name: cancel-ralph
description: Cancel active Ralph Wiggum loop
---

# Cancel Ralph Loop

Checking for active Ralph loop...

```bash
RALPH_STATE_FILE=".claude/ralph-loop.local.md"

if [[ -f "$RALPH_STATE_FILE" ]]; then
  ITERATION=$(grep '^iteration:' "$RALPH_STATE_FILE" | sed 's/iteration: *//')
  rm "$RALPH_STATE_FILE"
  echo "✅ Ralph loop cancelled after $ITERATION iterations."
  echo "   State file removed: $RALPH_STATE_FILE"
else
  echo "ℹ️  No active Ralph loop found."
  echo "   (No state file at $RALPH_STATE_FILE)"
fi
```
