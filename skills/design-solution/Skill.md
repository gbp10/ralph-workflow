---
name: design-solution
description: Research-first solution design that produces Implementation Blueprints for PRDs. Use after /create-prd to design HOW to build a feature through mandatory codebase research, UI/UX analysis, and architectural design.
---

# /design-solution

Convert a PRD into an Implementation Blueprint through mandatory research and architectural design.

## Overview

This skill bridges the gap between product requirements (PRD) and implementation stories by enforcing a disciplined research phase before any solution design begins.

**Pipeline Position:**
```
/create-prd → /design-solution → /solution-to-stories → ralph-orchestrator
     ↓              ↓                    ↓                    ↓
   WHAT          HOW               WHAT TO DO            EXECUTE
```

## CRITICAL: Research-First Methodology

> **DO NOT design any solution until you have completed ALL mandatory research phases.**

Without proper research, your blueprint will be based on assumptions, contaminating the entire Ralph workflow and leading to:
- Stories that don't fit the codebase
- Architectural decisions that conflict with existing patterns
- Wasted execution tokens on rework

---

## Phase 1: Mandatory Research

### Before You Start
1. Verify PRD exists at `.claude/ralph/specs/[feature-name]/requirements.md`
2. Create research directory: `.claude/ralph/specs/[feature-name]/research/`
3. Read the PRD thoroughly to understand what needs to be built

### Research Areas (ALL REQUIRED)

Complete each area and save findings to the specified file:

| # | Area | Output File | Investigation |
|---|------|-------------|---------------|
| 1 | **Codebase Patterns** | `research/codebase-patterns.md` | Glob/Grep for similar features, identify naming conventions, design patterns |
| 2 | **Architecture Mapping** | `research/architecture.md` | Read architecture docs, trace module boundaries, identify where feature fits |
| 3 | **Database/Data Model** | `research/database.md` | Query schemas, read migrations, map entity relationships |
| 4 | **API Surface** | `research/api-surface.md` | Read routes, OpenAPI specs, identify endpoints to extend |
| 5 | **Dependency Analysis** | `research/dependencies.md` | Check package manifests, trace external service calls |
| 6 | **Security Constraints** | `research/security.md` | Read auth middleware, identify data sensitivity, compliance requirements |
| 7 | **Performance Baselines** | `research/performance.md` | Check metrics/SLAs, identify bottlenecks |
| 8 | **Prior Art** | `research/prior-art.md` | Search git history, related PRs/issues, technical debt |
| 9 | **UI/UX Analysis** | `research/ui-ux/analysis.md` | Browser-based screen capture and flow tracing |

### Research Document Template

Use the templates from `${CLAUDE_PLUGIN_ROOT}/templates/RESEARCH_TEMPLATES.md`

Each research document must include:
- Investigation scope (what was examined)
- Findings with evidence (file paths, code snippets)
- Constraints discovered
- Open questions

### UI/UX Browser Research

Analyze the PRD and generate investigation directives:

**Type A: Explicit Screens** (from PRD requirements)
```
Required Screen Captures:
1. [Screen Name] - Navigate to: [path] - Capture: [what to observe]
2. [Screen Name] - Navigate to: [path] - Capture: [what to observe]
```

**Type B: Flow-Based Investigation** (user journeys)
```
Required Flow Traces:
Flow: "[User action description]"
1. Starting point: [where the flow begins]
2. Each step: [capture screens along the way]
3. Success/error states: [capture outcomes]
```

Save screenshots to:
```
research/ui-ux/screenshots/
├── screens/
│   ├── 01-[screen-name].png
│   └── ...
├── flows/
│   └── [flow-name]/
│       ├── step-01-[description].png
│       └── ...
└── README.md
```

### Checkpoint 1: Research Complete

Before proceeding, verify ALL research files exist:

```
□ research/codebase-patterns.md
□ research/architecture.md
□ research/database.md
□ research/api-surface.md
□ research/dependencies.md
□ research/security.md
□ research/performance.md
□ research/prior-art.md
□ research/ui-ux/analysis.md
□ research/ui-ux/screenshots/ (with README.md)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ CHECKPOINT 1 PASSED → Proceed to Synthesis
```

---

## Phase 2: Research Synthesis

### Purpose
Transform 9 separate research documents into a coherent understanding before designing the solution.

### Synthesis Activities

**1. Identify Conflicts/Tensions**
Look for findings that conflict with each other:
- Performance requirement vs. security overhead
- Existing pattern vs. PRD requirement
- Different conventions in different parts of codebase

Document each conflict with a proposed resolution.

**2. Note Gaps Requiring Assumptions**
For anything you couldn't determine:
- State what's unknown
- Make an explicit assumption
- Document the risk if assumption is wrong

**3. Consolidate Constraints**
Gather all constraints from research into categories:
- From Codebase Patterns
- From Architecture
- From Security
- From UI/UX
- From Performance

### Synthesis Document

Save to: `.claude/ralph/specs/[feature-name]/research-synthesis.md`

```markdown
# Research Synthesis: [Feature Name]

## Executive Summary
[2-3 paragraphs summarizing what research revealed]

## Conflicts & Resolutions
[Document each conflict found]

## Gaps & Assumptions
[Document unknowns with explicit assumptions]

## Consolidated Constraints
[Organized by category]

## Key Insights
[Non-obvious discoveries]

## Readiness Assessment
- [ ] All critical questions answered
- [ ] Assumptions documented and acceptable
- [ ] Constraints are clear and non-contradictory
- [ ] Ready to proceed to solution design
```

### Checkpoint 2: Synthesis Complete

```
□ research-synthesis.md exists
□ All conflicts have resolution approaches
□ All gaps have explicit assumptions with risk levels
□ Constraints are consolidated and non-contradictory
□ Readiness assessment checkboxes complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ CHECKPOINT 2 PASSED → Proceed to Blueprint Creation
```

---

## Phase 3: Implementation Blueprint

### Purpose
Design the solution architecture layer by layer, producing actionable guidance for `/solution-to-stories`.

### Blueprint Structure

Use template from: `${CLAUDE_PLUGIN_ROOT}/templates/IMPLEMENTATION_BLUEPRINT.md`

Save to: `.claude/ralph/specs/[feature-name]/implementation-blueprint.md`

### Required Sections

1. **Metadata** - PRD reference, research reference, timestamp
2. **Research Synthesis Summary** - Key findings, constraints, assumptions
3. **Solution Architecture by Layer:**
   - Data Layer (approach, constraints, suggested files)
   - Service Layer (approach, constraints, suggested files)
   - API Layer (approach, constraints, suggested files)
   - UI Layer (approach, constraints, suggested files)
4. **Cross-Cutting Concerns** - Auth, errors, logging
5. **Integration Points** - External systems
6. **Risk Assessment** - With mitigations
7. **Constraints for Story Generation** - Rules `/solution-to-stories` MUST follow
8. **Story Sequencing Recommendation** - Execution order

### Layer Design Guidelines

For each layer, document:

**Approach:** 2-3 sentences explaining WHAT will be built and WHY this approach was chosen (based on research findings).

**Constraints:** Specific rules this layer must follow, derived from research.

**Suggested Files:**
| Action | File Path | Purpose |
|--------|-----------|---------|
| Create/Modify | `exact/path/to/file.ext` | What this file does |

### Constraints for Story Generation

This section is CRITICAL. List every rule that `/solution-to-stories` must enforce:

```markdown
## Constraints for Story Generation

> **IMPORTANT:** These rules MUST be enforced by `/solution-to-stories`

1. [Constraint from codebase patterns]
2. [Constraint from architecture]
3. [Constraint from security]
4. [Constraint from UI/UX]
5. [Constraint from database]
...
```

---

## Output Summary

After completing all phases, you will have created:

```
.claude/ralph/specs/[feature-name]/
├── requirements.md              (input - already exists from /create-prd)
├── research/
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
│           ├── screens/
│           ├── flows/
│           └── README.md
├── research-synthesis.md
└── implementation-blueprint.md  (output - ready for /solution-to-stories)
```

---

## Next Steps

After blueprint is complete:

```
Run: /solution-to-stories [feature-name]
```

This will consume the blueprint and generate INVEST-validated user stories with:
- Layer assignments
- Constraint enforcement
- Proper sequencing
- Token budgets

Then execute with:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-orchestrator.sh .claude/ralph/specs/[feature-name]/stories.json
```
