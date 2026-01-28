---
name: ralph-pipeline
description: Trigger the complete Ralph workflow from a feature description or document. Runs all 4 phases autonomously: PRD creation, solution design, story conversion, and execution.
---

# /ralph-pipeline

Trigger the complete Ralph workflow for autonomous feature development.

## Overview

This skill chains all 4 phases of the Ralph workflow:

```
/create-prd → /design-solution → /solution-to-stories → ralph-orchestrator
     ↓              ↓                    ↓                    ↓
   WHAT          HOW               WHAT TO DO            EXECUTE
```

**All phases run with `--dangerously-skip-permissions` for fully autonomous execution.**

---

## Usage

### From Command Line (Bash)

```bash
# Basic usage
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh "Add user authentication with JWT"

# With feature name
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh --feature-name "user-auth" "Add user auth"

# From a document
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh --from-doc docs/requirements/auth.md

# Skip phases (if some already complete)
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh --feature-name "user-auth" --skip prd,solution

# Control max iterations per story
MAX_ITERATIONS=30 ${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh "Feature description"
```

### From Within Claude Code (This Skill)

When this skill is invoked, provide:
1. Feature description (what you want to build)
2. Optional: feature name

Then execute:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh --feature-name "[feature-name]" "[description]"
```

---

## Pipeline Phases

### Phase 1: PRD Creation
- Invokes `/create-prd` logic
- Researches codebase before writing
- Outputs: `ralph/specs/[feature]/requirements.md`
- Completion signal: `<promise>PRD COMPLETE</promise>`

### Phase 2: Solution Design
- Invokes `/design-solution` logic
- Runs 9 mandatory research areas
- Creates synthesis and blueprint
- Outputs: `ralph/specs/[feature]/implementation-blueprint.md`
- Completion signal: `<promise>BLUEPRINT COMPLETE</promise>`

### Phase 3: Story Conversion
- Invokes `/solution-to-stories` logic
- Validates blueprint
- Creates INVEST-validated stories
- Outputs: `ralph/specs/[feature]/stories.json`
- Completion signal: `<promise>STORIES COMPLETE</promise>`

### Phase 4: Execution (with Layer Agent Delegation)
- Runs `ralph-orchestrator.sh`
- **Delegates each story to specialized layer agents via Task tool:**
  - `data` layer → `ralph-workflow:ralph-data-layer`
  - `service` layer → `ralph-workflow:ralph-service-layer`
  - `api` layer → `ralph-workflow:ralph-api-layer`
  - `ui` layer → `ralph-workflow:ralph-ui-layer`
- Each agent has focused context for its architectural layer
- Uses `--dangerously-skip-permissions`
- Auto-commits between stories
- Completion signal: `<promise>[STORY-ID] COMPLETE</promise>` per story

---

## Skip Phases

If you already have some artifacts, skip phases:

```bash
# Already have PRD, skip to solution design
--skip prd

# Already have PRD and blueprint, skip to stories
--skip prd,solution

# Already have stories, just execute
--skip prd,solution,stories
```

---

## Output Structure

After completion:

```
ralph/specs/[feature]/
├── requirements.md              # PRD
├── research/                    # 9 research documents
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
├── research-synthesis.md        # Synthesis
└── implementation-blueprint.md  # Blueprint

ralph/
├── stories/[feature].json       # User stories
└── ralph-pipeline.log           # Execution log
```

---

## Layer Agent Delegation

By default, the orchestrator delegates stories to specialized layer agents:

| Story Layer | Agent | Specialization |
|-------------|-------|----------------|
| `data` | `ralph-workflow:ralph-data-layer` | Supabase, migrations, types |
| `service` | `ralph-workflow:ralph-service-layer` | Business logic, utilities |
| `api` | `ralph-workflow:ralph-api-layer` | Routes, validation, responses |
| `ui` | `ralph-workflow:ralph-ui-layer` | React, Tailwind, accessibility |

**Benefits:**
- Focused context per layer (better quality)
- Layer-specific patterns and best practices
- Reduced token usage per story

**To disable layer agents:**
```bash
USE_LAYER_AGENTS=false ./ralph-full-pipeline.sh "Feature description"
```

---

## Permissions

The entire pipeline runs with `--dangerously-skip-permissions`:
- No user approval prompts during execution
- Fully autonomous from start to finish
- Use with caution on production codebases

---

## Example

```bash
# Trigger full pipeline for a user authentication feature
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-full-pipeline.sh \
    --feature-name "user-auth" \
    "Add user authentication with JWT tokens, refresh token rotation,
     password reset flow, and email verification. Include rate limiting
     and audit logging for security compliance."
```

This will:
1. Create a comprehensive PRD
2. Research the codebase across 9 dimensions
3. Design a layer-centric solution
4. Generate INVEST-validated stories
5. Execute all stories autonomously

---

## Monitoring Progress

```bash
# Watch the log file
tail -f ralph/ralph-pipeline.log

# Check current phase
grep "PHASE" ralph/ralph-pipeline.log | tail -1

# Check story progress
grep "COMPLETE" ralph/ralph-pipeline.log
```
