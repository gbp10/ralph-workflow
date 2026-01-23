---
name: prd-to-json
description: Use when converting a PRD (Product Requirements Document) into a JSON array of user stories for Ralph Wiggum execution. Each story is scoped to fit within Claude's context window during execution.
---

# PRD to JSON Converter

## Purpose
Convert a PRD into a JSON array of **gold-standard user stories** following industry best practices, scoped to fit within Claude's **context window** during execution.

## Industry Best Practices Applied

### 1. INVEST Criteria (Mandatory Validation)
Every story is validated against:
- **I**ndependent - Minimize dependencies
- **N**egotiable - Allow implementation flexibility
- **V**aluable - Delivers visible value
- **E**stimable - Clear enough to estimate
- **S**mall - Fits in token budget
- **T**estable - Clear pass/fail criteria

### 2. User Story Format
```
As a [user role],
I want [goal/capability],
So that [benefit/value].
```

### 3. Acceptance Criteria in Gherkin (Given/When/Then)
```gherkin
Scenario: Happy path
  Given [precondition]
  When [action]
  Then [expected result]

Scenario: Error handling
  Given [error condition]
  When [action]
  Then [error response]
```

### 4. Definition of Done (Global)
- Build succeeds
- Tests pass with good coverage on new code
- Integration tests pass (if applicable)
- No security vulnerabilities
- All Gherkin scenarios verified
- Knowledge files updated

### 5. Edge Cases and Error Scenarios
- Happy path
- Error handling (404, 400, 500)
- Authorization (403)
- Concurrency conflicts (409)

### 6. Non-Functional Requirements
- Performance targets
- Security requirements
- Scalability needs

### 7. Test Strategy Per Story
- Unit tests (with naming convention)
- Integration tests
- Regression tests

### 8. Rollback Plan
- Database migration rollback (if applicable)
- Feature flags if needed
- Single commit for easy revert

## Execution Token Budget

**Critical:** The token limit is the **projected total tokens** Claude consumes during execution:

| Complexity | Budget | Scope |
|------------|--------|-------|
| Small | ~20-35K | 1-2 files |
| Medium | ~40-55K | 2-3 files |
| Large | ~60-75K | 3-5 files |
| Maximum | ~80K | Leave buffer |

## Output Location
```
.claude/ralph-workflow/stories/[feature-name].json
```

## Full Documentation
See `.claude/ralph-workflow/templates/PRD_TO_JSON.md` for:
- Complete JSON schema with all fields
- Token estimation formulas
- Story splitting guidelines
- Warning signs checklist
- Industry references
