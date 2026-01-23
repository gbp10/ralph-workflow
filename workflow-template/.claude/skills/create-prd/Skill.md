---
name: create-prd
description: Use when creating a Product Requirements Document (PRD) for a new feature. This skill enforces mandatory context-gathering from codebase, database, and UI before writing the PRD. Use this to ensure PRDs are based on real research, not assumptions.
---

# Create PRD (Product Requirements Document)

## Purpose
Create a comprehensive Product Requirements Document following industry best practices that can be converted to actionable user stories for Ralph Wiggum execution.

## CRITICAL: Research First, Write Second

**DO NOT write any PRD content until you have completed the mandatory context-gathering phase.**

Without proper context gathering, the PRD will be based on assumptions, contaminating the entire Ralph workflow.

## Phase 1: Research (MANDATORY)

### 1.1 Codebase Research
```bash
# Find related entities
Glob: "src/**/*[keyword]*.{ts,js,py,cs}"

# Search for existing patterns
Grep: "[keyword]" --type [language]

# Read service implementations
Read: "src/services/[ServiceName].ts"
```

### 1.2 Database Schema Research (if applicable)
```bash
# Query your database for related tables
# Adjust connection and queries for your database type
```

### 1.3 Documentation Review
- Check existing specs and documentation
- Check any domain-specific skills
- Review knowledge files if they exist

### 1.4 UI Research (If Applicable)
- Navigate to the feature area
- Take screenshots for context
- Document current user workflow

## Phase 2: Write PRD

After completing research, create the PRD following the template at:
`.claude/ralph-workflow/templates/CREATE_PRD.md`

### Key Sections
1. **Problem Statement** - What problem are we solving?
2. **Target Users** - Who is affected?
3. **User Scenarios** - How do users interact?
4. **Goals & Success Metrics** - SMART goals
5. **Scope** - In scope, out of scope, assumptions
6. **User Stories** - With token budgets and passing criteria
7. **Technical Design** - Database, API, Service changes
8. **Testing Strategy** - Full-stack scope
9. **Rollout Plan** - DEV → STG → PROD

## Phase 3: Define Passing Criteria

**Each user story MUST have clear passing criteria:**

### Code Quality Gates
- Build succeeds with no errors
- All tests pass

### Full-Stack Test Requirements
- Database layer tests (if applicable)
- Service/Repository layer tests
- API/Controller layer tests
- UI/E2E tests (if applicable)
- Integration tests

## Output Location
```
.kiro/specs/[feature-name]/requirements.md
```

## Full Template
See `.claude/ralph-workflow/templates/CREATE_PRD.md` for the complete PRD template with all sections.
