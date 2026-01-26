---
name: solution-to-stories
description: Convert Implementation Blueprints into INVEST-validated user stories for Ralph execution. Use after /design-solution to generate executable stories with layer assignments, constraint enforcement, and proper sequencing.
---

# /solution-to-stories

Convert an Implementation Blueprint into a JSON array of gold-standard user stories following INVEST criteria, scoped to fit within Claude's context window during execution.

## Overview

This skill consumes the Implementation Blueprint produced by `/design-solution` and generates executable user stories organized by architectural layer.

**Pipeline Position:**
```
/create-prd → /design-solution → /solution-to-stories → ralph-orchestrator
                                       ↑ YOU ARE HERE
```

## Pre-flight Validation

Before generating stories, verify:

```
□ Blueprint exists: .kiro/specs/[feature]/implementation-blueprint.md
□ Blueprint has Metadata section
□ Blueprint has all 4 layer sections (Data, Service, API, UI)
□ Blueprint has "Constraints for Story Generation" section
□ Research folder exists: .kiro/specs/[feature]/research/
□ Research synthesis exists: .kiro/specs/[feature]/research-synthesis.md
```

**If validation fails:** Error with message to run `/design-solution` first.

---

## Input: Implementation Blueprint

Read the blueprint from: `.kiro/specs/[feature-name]/implementation-blueprint.md`

Extract:
1. **Suggested Files** per layer → populates `files_to_read`, `files_to_modify`, `files_to_create`
2. **Constraints for Story Generation** → embeds in acceptance criteria and prompts
3. **Story Sequencing Recommendation** → determines `depends_on` relationships
4. **Layer assignments** → groups stories by architectural layer

---

## INVEST Validation (Mandatory)

Every story MUST satisfy:

| Criterion | Standard |
|-----------|----------|
| **I**ndependent | Developable without blocking dependencies |
| **N**egotiable | Implementation flexibility preserved |
| **V**aluable | Delivers measurable user/business benefit |
| **E**stimable | Team can forecast effort required |
| **S**mall | Fits within 80K token execution budget |
| **T**estable | Clear pass/fail acceptance criteria |

---

## User Story Format

```
As a [user role],
I want [goal/capability],
So that [benefit/value].
```

---

## Acceptance Criteria (Gherkin)

Replace checklists with Given/When/Then scenarios:

```gherkin
Scenario: [Human-readable description]
  Given [precondition]
  When [action taken]
  Then [expected result(s)]
```

**Minimum coverage:**
- Happy path
- Error handling (400, 404, 500, 403, 409)
- Authorization
- Boundary conditions

---

## Definition of Done (Global)

- Build succeeds
- Tests pass with good coverage on new code
- Integration tests pass (if applicable)
- No security vulnerabilities
- All Gherkin scenarios verified
- Knowledge files updated

---

## Execution Token Budget

**Critical:** The token limit is the **projected total tokens** Claude consumes during execution:

| Complexity | Budget | Scope |
|------------|--------|-------|
| Small | ~20-35K | 1-2 files |
| Medium | ~40-55K | 2-3 files |
| Large | ~60-75K | 3-5 files |
| Maximum | ~80K | Leave buffer |

---

## Layer-Based Story Organization

Stories are grouped by architectural layer from the blueprint:

```json
"story_groups": {
  "data_layer": ["US-001", "US-002"],
  "service_layer": ["US-003"],
  "api_layer": ["US-004", "US-005"],
  "ui_layer": ["US-006", "US-007"]
}
```

Execution order follows blueprint recommendation (typically Data → Service → API → UI).

---

## Constraint Enforcement

For each story, the skill MUST:

1. Read "Constraints for Story Generation" from blueprint
2. Embed applicable constraints in:
   - Story prompt
   - Acceptance criteria
   - Test strategy
3. Populate file lists from blueprint's "Suggested Files"
4. Set `depends_on` based on "Story Sequencing Recommendation"
5. Assign `layer` field based on which section the story implements

---

## Enhanced JSON Schema

The JSON output includes new fields for blueprint integration:

- `blueprint_path` - Reference to the implementation blueprint
- `blueprint_metadata` - Constraints and assumptions from blueprint
- `story_groups` - Stories organized by layer
- `execution_order` - Recommended execution sequence
- Per-story `layer` field - Which architectural layer
- Per-story `blueprint_reference` - Traceability to blueprint section

---

## Output Location

```
.claude/ralph-workflow/stories/[feature-name].json
```

---

## Full Documentation

See `${CLAUDE_PLUGIN_ROOT}/templates/PRD_TO_JSON.md` for:
- Complete JSON schema with all fields
- Token estimation formulas
- Story splitting guidelines
- Warning signs checklist

---

## Next Steps

After stories are generated:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/ralph-orchestrator.sh .claude/ralph-workflow/stories/[feature-name].json
```

This executes stories via ralph-loop in the sequence defined by `execution_order`.

The orchestrator runs with `--dangerously-skip-permissions` for fully autonomous execution.
