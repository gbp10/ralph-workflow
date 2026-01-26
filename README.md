# Ralph Workflow

A complete AI-driven development workflow for Claude Code, featuring self-referential iteration loops, research-first solution design, and PRD-to-execution pipelines.

## Installation

```bash
# Install the Ralph Workflow plugin
claude /install-plugin https://github.com/gbp10/ralph-workflow
```

This installs all skills, commands, and hooks globally.

---

## Plugin Structure

```
ralph-workflow/
├── plugin.json           # Plugin manifest
├── skills/               # All skills
│   ├── create-prd/       # PRD creation (research-first)
│   ├── design-solution/  # Solution design with mandatory research
│   ├── solution-to-stories/ # Blueprint → user stories
│   ├── ralph-loop/       # Self-referential iteration loop
│   ├── ralph-pipeline/   # End-to-end workflow trigger
│   └── advance-story/    # Story advancement helper
├── commands/             # User commands
│   ├── cancel-ralph.md   # Cancel active loop
│   └── ralph-loop.md     # Start loop command
├── hooks/                # Event hooks
│   ├── hooks.json        # Hook configuration
│   └── stop-hook.sh      # Stop hook for loop control
├── scripts/              # Automation scripts
│   ├── ralph-loop.sh     # Loop setup script
│   ├── ralph-orchestrator.sh  # Multi-story runner
│   └── ralph-full-pipeline.sh # End-to-end pipeline
└── templates/            # Reference templates
    ├── CREATE_PRD.md     # PRD template
    ├── PRD_TO_JSON.md    # Story conversion guide
    ├── RESEARCH_TEMPLATES.md  # Research area templates
    └── IMPLEMENTATION_BLUEPRINT.md # Blueprint template
```

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

### Option A: Run Full Pipeline (Autonomous)

```bash
# End-to-end: PRD → Solution → Stories → Execute
/ralph-pipeline "Add user authentication with JWT"
```

Or via script:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh "Add user authentication"
```

### Option B: Run Each Phase Manually

```bash
# Phase 1: Create a PRD (research-first)
/create-prd "Add user authentication feature"

# Phase 2: Design the solution (mandatory research + blueprint)
/design-solution

# Phase 3: Convert blueprint to user stories
/solution-to-stories

# Phase 4: Execute all stories autonomously
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-orchestrator.sh
```

### Option C: Just Use Ralph Loop

```bash
# Simple iterative development
/ralph-loop Build a REST API --completion-promise 'DONE' --max-iterations 20
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
│            │  EXIT    │  │ Feed same     │                │
│            │          │  │ prompt back   │──────┐         │
│            └──────────┘  └───────────────┘      │         │
│                                    ↑             │         │
│                                    └─────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase Details

### Phase 1: Create PRD (`/create-prd`)

Research-first approach:
1. Search codebase for related code
2. Query database for schema understanding
3. Review existing documentation
4. Write comprehensive PRD with SMART goals

Output: `.kiro/specs/[feature]/requirements.md`

### Phase 2: Design Solution (`/design-solution`)

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

**Automated (all stories) - RECOMMENDED:**
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-orchestrator.sh
```

The orchestrator:
- Loads stories from JSON
- Executes in layer order (Data → Service → API → UI)
- Runs with `--dangerously-skip-permissions` (no approval prompts)
- Commits progress between stories
- Clears context for fresh sessions

**Manual (per story):**
```bash
/ralph-loop "Implement US-001" --completion-promise "US-001 COMPLETE" --max-iterations 20
```

---

## Output Locations (User's Project)

When the workflow runs, it creates files in your project:

```
your-project/
├── .claude/
│   └── ralph-workflow/
│       ├── prompts/
│       │   └── CURRENT_TASK.md      # Active task (generated)
│       └── stories/
│           └── [feature].json       # User story files
└── .kiro/
    └── specs/
        └── [feature]/
            ├── requirements.md       # PRD output
            ├── research/             # Research documents
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
            ├── research-synthesis.md # Synthesis
            └── implementation-blueprint.md # Blueprint
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
