# Knowledge Files

Store project-specific knowledge files here that should be pre-loaded into Ralph's context.

## Recommended Files

1. **DATABASE_SCHEMA.md** - Your database schema reference
2. **INFRASTRUCTURE.md** - Your infrastructure and deployment info
3. **TESTING_GUIDE.md** - Your testing procedures and conventions

## Example DATABASE_SCHEMA.md

```markdown
# Database Schema Reference

## Connection Strings
- DEV: `your-dev-connection`
- STG: `your-staging-connection`
- PROD: `your-prod-connection` (read-only access recommended)

## Core Tables

### users
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| email | VARCHAR(255) | Unique email |
| created_at | DATETIME | Creation timestamp |

### orders
...
```

## Usage

Reference these files in your story JSON:
```json
{
  "knowledge_files": {
    "pre_load": [
      ".claude/ralph-workflow/knowledge/DATABASE_SCHEMA.md",
      ".claude/ralph-workflow/knowledge/INFRASTRUCTURE.md"
    ]
  }
}
```
