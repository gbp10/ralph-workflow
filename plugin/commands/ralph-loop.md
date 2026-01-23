---
name: ralph-loop
description: Start Ralph Wiggum loop in current session. Use for iterative development with self-referential prompts.
arguments: PROMPT --max-iterations N --completion-promise "TEXT"
---

# Ralph Loop Command

Starting Ralph loop with your task...

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-loop.sh" $ARGUMENTS
```

## How It Works

1. Creates `.claude/ralph-loop.local.md` state file with your prompt
2. The Stop hook intercepts exit attempts
3. Your same prompt is fed back, but you see modified files from previous iteration
4. Loop continues until completion promise detected or max iterations reached

## Completion

When your task is genuinely complete, output:
```
<promise>YOUR_COMPLETION_TEXT</promise>
```

The promise must be TRUE - do not lie to exit the loop.
