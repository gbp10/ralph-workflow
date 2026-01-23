# Ralph Workflow Template

Copy this directory structure to your project to use the full PRD-to-execution workflow.

## Installation

```bash
# Copy to your project
cp -r .claude your-project/
cp -r .kiro your-project/
```

## Usage

### 1. Create a PRD

```bash
/create-prd "Your feature description"
```

This researches your codebase first, then creates a comprehensive PRD.

### 2. Convert to Stories

```bash
/prd-to-json
```

This validates stories against INVEST criteria and creates execution-ready JSON.

### 3. Execute with Ralph

**Single story:**
```bash
/ralph-loop "Implement US-001" --completion-promise "US-001 COMPLETE" --max-iterations 20
```

**All stories:**
```bash
.claude/ralph-workflow/scripts/ralph-orchestrator.sh
```

## Customization

### Knowledge Files
Add your project-specific knowledge files to `.claude/ralph-workflow/knowledge/`:
- `DATABASE_SCHEMA.md` - Your database reference
- `INFRASTRUCTURE.md` - Your deployment info
- `TESTING_GUIDE.md` - Your testing procedures

### Skills
Modify the skills in `.claude/skills/` to match your project's conventions.

### Templates
Update the templates in `.claude/ralph-workflow/templates/` for your organization's PRD format.

## Directory Structure

```
.claude/
├── skills/
│   ├── create-prd/Skill.md
│   ├── prd-to-json/Skill.md
│   ├── ralph-loop/Skill.md
│   └── advance-story/Skill.md
└── ralph-workflow/
    ├── scripts/
    │   ├── ralph-loop.sh
    │   └── ralph-orchestrator.sh
    ├── templates/
    │   ├── CREATE_PRD.md
    │   └── PRD_TO_JSON.md
    ├── knowledge/
    ├── prompts/
    │   └── CURRENT_TASK.md
    └── stories/
        └── example.json
.kiro/
└── specs/
    └── README.md
```
