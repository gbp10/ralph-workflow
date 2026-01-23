# Ralph Loop Plugin

A Claude Code plugin that enables self-referential iterative development loops.

## What is Ralph?

Ralph is a **Stop hook** that intercepts Claude's exit attempts and feeds the same prompt back as input. Claude sees its previous work through modified files and git history, creating an autonomous iteration loop.

## Installation

### Option 1: Install from GitHub (Recommended)

```bash
claude /install-plugin https://github.com/gbp10/ralph-workflow/tree/main/plugin
```

### Option 2: Manual Installation

Copy the `plugin/` directory to your Claude plugins location:
```bash
cp -r plugin ~/.claude/plugins/ralph-loop
```

## Usage

### Start a Ralph Loop

```bash
/ralph-loop Build a REST API for todos --completion-promise 'DONE' --max-iterations 20
```

**Arguments:**
- `PROMPT` - The task description (required)
- `--max-iterations N` - Safety limit (default: unlimited)
- `--completion-promise "TEXT"` - Exit condition phrase

### Signal Completion

When your task is genuinely complete, output:
```
<promise>DONE</promise>
```

The promise text must match exactly what you specified in `--completion-promise`.

### Cancel a Loop

```bash
/cancel-ralph
```

## How It Works

1. **Setup** (`/ralph-loop`): Creates `.claude/ralph-loop.local.md` state file
2. **Stop Hook**: Intercepts exit, reads state file, checks for completion
3. **Loop**: If not complete, increments iteration and feeds same prompt back
4. **Exit**: When `<promise>TEXT</promise>` matches, or max iterations reached

## State File Format

```yaml
---
active: true
iteration: 3
max_iterations: 20
completion_promise: "DONE"
started_at: "2026-01-23T12:00:00Z"
---

Your original prompt here...
```

## Key Principles

1. **Same Prompt**: The prompt never changes - progress is seen through files
2. **Verifiable Exit**: Completion requires explicit promise output
3. **No Lying**: Only output promise when the statement is TRUE
4. **Cost Control**: Use `--max-iterations` as a safety net
