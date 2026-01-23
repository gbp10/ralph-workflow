# Ralph Workflow

A complete AI-driven development workflow for Claude Code, featuring self-referential iteration loops and PRD-to-execution pipelines.

## What's Inside

This repo contains two components:

### 1. `plugin/` - Ralph Loop Plugin
A Claude Code plugin that enables self-referential iterative development. Install it globally to use `/ralph-loop` in any project.

### 2. `workflow-template/` - Full PRD Workflow
A complete workflow template with:
- PRD creation skills (research-first approach)
- PRD-to-JSON conversion (INVEST-validated user stories)
- Ralph loop integration for autonomous execution
- Multi-story orchestrator for end-to-end feature development

---

## Quick Start

### Option A: Install Plugin Only

```bash
# Install the Ralph Loop plugin
claude /install-plugin https://github.com/gbp10/ralph-workflow/tree/main/plugin
```

Then use it anywhere:
```bash
/ralph-loop Build a REST API --completion-promise 'DONE' --max-iterations 20
```

### Option B: Use Full Workflow Template

Copy the workflow template to your project:
```bash
cp -r workflow-template/.claude your-project/
cp -r workflow-template/.kiro your-project/
```

Then use the skills:
```bash
# Create a PRD
/create-prd "Add user authentication feature"

# Convert to user stories
/prd-to-json

# Execute with Ralph
/ralph-loop "Implement US-001" --completion-promise "US-001 COMPLETE"

# Or run the orchestrator for all stories
.claude/ralph-workflow/scripts/ralph-orchestrator.sh
```

---

## How Ralph Works

Ralph is a **self-referential feedback system**:

1. **You provide a prompt** with a completion condition
2. **Claude works on the task** (writes code, runs tests, etc.)
3. **Claude tries to exit** when it thinks it's done
4. **The Stop hook intercepts** and checks for the completion promise
5. **If not complete**: Same prompt is fed back, Claude sees modified files
6. **If complete**: Loop exits

```
┌─────────────────────────────────────────────────────────────┐
│                     RALPH LOOP FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   /ralph-loop "Build API" --completion-promise "DONE"       │
│                         ↓                                   │
│              ┌─────────────────────┐                       │
│              │  Claude works on    │                       │
│              │  the task           │                       │
│              └──────────┬──────────┘                       │
│                         ↓                                   │
│              ┌─────────────────────┐                       │
│              │  Claude exits       │                       │
│              └──────────┬──────────┘                       │
│                         ↓                                   │
│              ┌─────────────────────┐                       │
│              │  Stop hook checks:  │                       │
│              │  <promise>DONE</    │                       │
│              │  promise> found?    │                       │
│              └──────────┬──────────┘                       │
│                    ╱         ╲                             │
│                  YES          NO                           │
│                   ↓            ↓                           │
│            ┌──────────┐  ┌───────────────┐                │
│            │  EXIT ✓  │  │ Feed same     │                │
│            │          │  │ prompt back   │──────┐         │
│            └──────────┘  └───────────────┘      │         │
│                                    ↑             │         │
│                                    └─────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## The Three-Phase Workflow

### Phase 1: Create PRD (`/create-prd`)

Research-first approach:
1. Search codebase for related code
2. Query database for schema understanding
3. Review existing documentation
4. Write comprehensive PRD with SMART goals

Output: `.kiro/specs/[feature]/requirements.md`

### Phase 2: Convert to Stories (`/prd-to-json`)

INVEST-validated conversion:
1. Validate each story against INVEST criteria
2. Write Gherkin acceptance criteria (Given/When/Then)
3. Estimate token budgets for execution
4. Split large stories that exceed budget

Output: `.claude/ralph-workflow/stories/[feature].json`

### Phase 3: Execute with Ralph

Two options:

**Manual (per story):**
```bash
/ralph-loop "Implement US-001" --completion-promise "US-001 COMPLETE" --max-iterations 20
```

**Automated (all stories):**
```bash
.claude/ralph-workflow/scripts/ralph-orchestrator.sh
```

---

## Directory Structure

```
your-project/
├── .claude/
│   ├── skills/
│   │   ├── create-prd/Skill.md      # PRD creation skill
│   │   ├── prd-to-json/Skill.md     # Story conversion skill
│   │   ├── ralph-loop/Skill.md      # Loop skill
│   │   └── advance-story/Skill.md   # Story advancement
│   └── ralph-workflow/
│       ├── scripts/
│       │   ├── ralph-loop.sh        # Loop setup
│       │   └── ralph-orchestrator.sh # Multi-story runner
│       ├── templates/
│       │   ├── CREATE_PRD.md        # PRD template
│       │   └── PRD_TO_JSON.md       # Conversion guide
│       ├── knowledge/               # Project knowledge files
│       ├── prompts/
│       │   └── CURRENT_TASK.md      # Active task (generated)
│       └── stories/
│           └── [feature].json       # User story files
└── .kiro/
    └── specs/
        └── [feature]/
            └── requirements.md       # PRD output
```

---

## Key Concepts

### Completion Promise
A verifiable statement that signals task completion:
```
<promise>DONE</promise>
```

**Rules:**
- Must be exactly as specified in `--completion-promise`
- Must be TRUE when output (no lying to exit!)
- Case-sensitive match

### Token Budget
Each user story is budgeted for Claude's context window:
- Small: ~20-35K tokens (1-2 files)
- Medium: ~40-55K tokens (2-3 files)
- Large: ~60-75K tokens (3-5 files)
- Max: ~80K tokens (leave buffer)

### INVEST Criteria
Every story must be:
- **I**ndependent - Minimal dependencies
- **N**egotiable - Flexible implementation
- **V**aluable - Delivers user value
- **E**stimable - Clear scope
- **S**mall - Fits in token budget
- **T**estable - Clear pass/fail criteria

---

## Configuration

### Environment Variables

```bash
# For orchestrator
MAX_ITERATIONS=50  # Max iterations per story (default: 50)
```

### State File

Ralph stores state in `.claude/ralph-loop.local.md`:
```yaml
---
active: true
iteration: 3
max_iterations: 20
completion_promise: "DONE"
started_at: "2026-01-23T12:00:00Z"
---

Your prompt here...
```

---

## Troubleshooting

### Loop won't stop
- Check that your `<promise>TEXT</promise>` matches exactly
- Use `--max-iterations` as a safety net
- Run `/cancel-ralph` to force stop

### Context overflow
- Split story into smaller pieces
- Reduce files_to_read in story JSON
- Use fresh sessions between stories

### Orchestrator fails
- Ensure `jq` is installed: `brew install jq`
- Ensure `claude` CLI is available
- Check stories JSON is valid: `jq . stories.json`

---

## License

MIT License - feel free to use and modify.

---

## Credits

Created for autonomous AI-driven development with Claude Code.
