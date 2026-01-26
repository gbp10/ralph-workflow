# Ralph Workflow

A complete AI-driven development workflow for Claude Code, featuring self-referential iteration loops, research-first solution design, and PRD-to-execution pipelines.

## What's Inside

This repo contains two components:

### 1. `plugin/` - Ralph Loop Plugin
A Claude Code plugin that enables self-referential iterative development. Install it globally to use `/ralph-loop` in any project.

### 2. `workflow-template/` - Full PRD Workflow
A complete workflow template with:
- PRD creation skills (research-first approach)
- **NEW:** Solution design with mandatory research (`/design-solution`)
- Story conversion from blueprints (`/solution-to-stories`)
- Ralph loop integration for autonomous execution
- Multi-story orchestrator for end-to-end feature development

---

## The Four-Phase Pipeline

```
/create-prd → /design-solution → /solution-to-stories → ralph-orchestrator
     ↓              ↓                    ↓                    ↓
   WHAT          HOW               WHAT TO DO            EXECUTE
 (requirements) (blueprint)        (stories)            (loops)
```

| Phase | Skill | Input | Output |
|-------|-------|-------|--------|
| 1 | `/create-prd` | Feature idea | `.kiro/specs/[feature]/requirements.md` |
| 2 | `/design-solution` | PRD | `.kiro/specs/[feature]/implementation-blueprint.md` |
| 3 | `/solution-to-stories` | Blueprint | `.claude/ralph-workflow/stories/[feature].json` |
| 4 | `ralph-orchestrator.sh` | Stories JSON | Implemented feature |

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

Then run the complete pipeline:
```bash
# Phase 1: Create a PRD (research-first)
/create-prd "Add user authentication feature"

# Phase 2: Design the solution (mandatory research + blueprint)
/design-solution

# Phase 3: Convert blueprint to user stories
/solution-to-stories

# Phase 4: Execute all stories autonomously
.claude/ralph-workflow/scripts/ralph-orchestrator.sh
```

**Note:** The orchestrator runs with `--dangerously-skip-permissions` for fully autonomous execution without user approval prompts.

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

## The Four-Phase Workflow Details

### Phase 1: Create PRD (`/create-prd`)

Research-first approach:
1. Search codebase for related code
2. Query database for schema understanding
3. Review existing documentation
4. Write comprehensive PRD with SMART goals

Output: `.kiro/specs/[feature]/requirements.md`

### Phase 2: Design Solution (`/design-solution`) ⭐ NEW

**Research Phase (9 mandatory areas):**
1. Codebase Patterns - naming, conventions, design patterns
2. Architecture Mapping - module boundaries, where feature fits
3. Database/Data Model - schemas, migrations, relationships
4. API Surface - routes, contracts, versioning
5. Dependency Analysis - packages, external services
6. Security Constraints - auth, data sensitivity, compliance
7. Performance Baselines - SLAs, bottlenecks, metrics
8. Prior Art - git history, related PRs, tech debt
9. UI/UX Analysis - browser-based screen capture and flow tracing

**Synthesis Phase:**
- Identify conflicts between findings
- Document gaps with explicit assumptions
- Consolidate constraints by category

**Blueprint Creation:**
- Layer-centric design (Data → Service → API → UI)
- Constraints + Suggested Files per layer
- Story sequencing recommendations

Output: `.kiro/specs/[feature]/implementation-blueprint.md`

### Phase 3: Convert to Stories (`/solution-to-stories`)

Blueprint-aware conversion:
1. Validate blueprint exists with all sections
2. Extract constraints and embed in stories
3. Validate each story against INVEST criteria
4. Write Gherkin acceptance criteria (Given/When/Then)
5. Estimate token budgets for execution
6. Group stories by architectural layer
7. Set execution order based on blueprint

Output: `.claude/ralph-workflow/stories/[feature].json`

### Phase 4: Execute with Ralph

Two options:

**Manual (per story):**
```bash
/ralph-loop "Implement US-001" --completion-promise "US-001 COMPLETE" --max-iterations 20
```

**Automated (all stories) - RECOMMENDED:**
```bash
.claude/ralph-workflow/scripts/ralph-orchestrator.sh
```

The orchestrator:
- Loads stories from JSON
- Executes in layer order (Data → Service → API → UI)
- Runs with `--dangerously-skip-permissions` (no approval prompts)
- Commits progress between stories
- Clears context for fresh sessions

---

## Directory Structure

```
your-project/
├── .claude/
│   ├── skills/
│   │   ├── create-prd/Skill.md         # PRD creation skill
│   │   ├── design-solution/Skill.md    # Solution design skill ⭐ NEW
│   │   ├── solution-to-stories/Skill.md # Story conversion skill
│   │   ├── ralph-loop/Skill.md         # Loop skill
│   │   └── advance-story/Skill.md      # Story advancement
│   └── ralph-workflow/
│       ├── scripts/
│       │   ├── ralph-loop.sh           # Loop setup
│       │   └── ralph-orchestrator.sh   # Multi-story runner
│       ├── templates/
│       │   ├── CREATE_PRD.md           # PRD template
│       │   ├── PRD_TO_JSON.md          # Conversion guide
│       │   ├── RESEARCH_TEMPLATES.md   # Research templates ⭐ NEW
│       │   └── IMPLEMENTATION_BLUEPRINT.md # Blueprint template ⭐ NEW
│       ├── knowledge/                  # Project knowledge files
│       ├── prompts/
│       │   └── CURRENT_TASK.md         # Active task (generated)
│       └── stories/
│           └── [feature].json          # User story files
└── .kiro/
    └── specs/
        └── [feature]/
            ├── requirements.md          # PRD output
            ├── research/                # Research documents ⭐ NEW
            │   ├── codebase-patterns.md
            │   ├── architecture.md
            │   ├── database.md
            │   ├── api-surface.md
            │   ├── dependencies.md
            │   ├── security.md
            │   ├── performance.md
            │   ├── prior-art.md
            │   └── ui-ux/
            │       ├── analysis.md
            │       └── screenshots/
            ├── research-synthesis.md    # Synthesis ⭐ NEW
            └── implementation-blueprint.md # Blueprint ⭐ NEW
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

### Layer-Based Execution
Stories are grouped and executed by architectural layer:
1. **Data Layer** - Models, migrations, entities
2. **Service Layer** - Business logic, services
3. **API Layer** - Routes, controllers, endpoints
4. **UI Layer** - Components, screens, flows

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

### Blueprint validation fails
- Ensure all 4 layer sections exist (Data, Service, API, UI)
- Ensure "Constraints for Story Generation" section exists
- Run `/design-solution` to create blueprint first

---

## License

MIT License - feel free to use and modify.

---

## Credits

Created for autonomous AI-driven development with Claude Code.
