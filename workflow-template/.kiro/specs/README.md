# Specifications Directory

PRD (Product Requirements Document) files are stored here.

## Structure

```
.kiro/specs/
├── [feature-name]/
│   ├── requirements.md    # The main PRD
│   ├── design.md          # Technical design (optional)
│   └── tasks.md           # Implementation tasks (optional)
```

## Creating a PRD

Use the `/create-prd` skill:

```bash
/create-prd "Add user authentication feature"
```

This will:
1. Research the codebase for related code
2. Gather context from documentation
3. Create a comprehensive PRD with:
   - Problem statement
   - User personas
   - User scenarios
   - SMART goals
   - User stories with acceptance criteria
   - Technical design
   - Testing strategy
   - Rollout plan

## Converting to Stories

After the PRD is approved, convert it to user stories:

```bash
/prd-to-json
```

Output: `.claude/ralph-workflow/stories/[feature-name].json`
