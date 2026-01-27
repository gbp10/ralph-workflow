---
name: ralph-loop
description: Start Ralph Wiggum loop in current session. Use for iterative development with self-referential prompts.
---

# Ralph Loop Skill

Start an iterative development loop where Claude works on a task autonomously until completion.

## Usage

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-loop.sh $ARGUMENTS
```

## Arguments

- `PROMPT` - The task description (required, can be multiple words)
- `--max-iterations N` - Maximum iterations before auto-stop (default: 0 = unlimited)
- `--completion-promise "TEXT"` - Promise phrase that signals completion

## Examples

```bash
# Basic usage with safety limits
/ralph-loop Build a todo API --completion-promise 'DONE' --max-iterations 20

# Fix a bug with iteration limit
/ralph-loop --max-iterations 10 Fix the authentication bug

# Refactor with no limit (dangerous!)
/ralph-loop Refactor the cache layer
```

## How It Works

1. Creates `.claude/ralph/state/loop.local.md` state file with your prompt
2. The Stop hook intercepts exit attempts
3. Same prompt is fed back - progress visible through modified files
4. Loop continues until:
   - `<promise>TEXT</promise>` matches completion-promise
   - OR max iterations reached

## Completion

When the task is genuinely complete, output:

```
<promise>YOUR_COMPLETION_PROMISE</promise>
```

**IMPORTANT:**
- Use `<promise>` XML tags EXACTLY as shown
- The statement MUST be TRUE
- Do NOT lie to exit the loop
- Trust the process

## Monitoring

```bash
# View current iteration
grep '^iteration:' .claude/ralph/state/loop.local.md

# View full state
head -10 .claude/ralph/state/loop.local.md
```

## Cancel

```bash
/cancel-ralph
```
