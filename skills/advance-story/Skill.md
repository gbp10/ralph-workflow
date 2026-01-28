---
name: advance-story
description: Advance to the next user story in the Ralph workflow after current story is complete
---

# Advance Story Skill

Move to the next user story after completing the current one.

## When to Use

After you've completed a user story and output its completion promise, use this skill to:
1. Mark the current story as "completed" in the JSON file
2. Generate `CURRENT_TASK.md` for the next story
3. Commit progress
4. Prepare for the next iteration

## Process

### Step 1: Verify Current Story Completion
- Confirm all acceptance criteria are met
- Confirm all tests pass
- Confirm completion promise was output

### Step 2: Update Story Status

```bash
# Find the stories JSON file
STORIES_FILE="ralph/specs/[feature-name]/stories.json"

# Mark current story as completed
jq '(.user_stories[] | select(.id == "CURRENT_STORY_ID") | .status) = "completed"' "$STORIES_FILE" > tmp.json && mv tmp.json "$STORIES_FILE"
```

### Step 3: Generate Next Task

```bash
# Read next incomplete story
NEXT_STORY=$(jq -r '.user_stories[] | select(.status != "completed") | .id' "$STORIES_FILE" | head -1)

# Generate CURRENT_TASK.md from the next story's prompt
```

### Step 4: Commit Progress

```bash
git add -A
git commit -m "Complete [STORY_ID], advance to [NEXT_STORY_ID]

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 5: Context Management

For best results, start a new Claude session for the next story to get fresh context.

## Automated Alternative

Use the orchestrator script for fully automated multi-story execution:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-orchestrator.sh ralph/specs/[feature]/stories.json
```
