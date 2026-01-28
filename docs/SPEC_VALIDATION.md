# Ralph-Workflow Spec Validation Against Claude Code Standards

> **Validation Date:** 2025-01-28 | **Claude Code Docs Version:** Latest (code.claude.com)

This document validates the proposed ralph-workflow enhancements against the official Claude Code specifications for plugins, agents, skills, and hooks.

---

## 1. Plugin Structure Validation

### Official Specification (from [Plugins Reference](https://code.claude.com/docs/en/plugins-reference))

**Required Structure:**
```
plugin-name/
├── .claude-plugin/           # Metadata directory
│   └── plugin.json          # Required: plugin manifest
├── commands/                 # Default command location (legacy)
├── agents/                   # Default agent location
├── skills/                   # Agent Skills
├── hooks/                    # Hook configurations
│   └── hooks.json
├── .mcp.json                # MCP server definitions
└── scripts/                 # Hook and utility scripts
```

**Critical Rules:**
- Components must be at plugin root, NOT inside `.claude-plugin/`
- Only `plugin.json` belongs in `.claude-plugin/`
- Use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin path references

### Our Proposed Structure

```
ralph-workflow/
├── .claude-plugin/
│   └── plugin.json          ✅ Correct location
├── agents/                   ✅ At root level
├── skills/                   ✅ At root level
├── hooks/
│   └── hooks.json           ✅ At root level
└── scripts/                 ✅ At root level
```

### plugin.json Required Fields

| Field | Required | Our Status |
|-------|----------|------------|
| `name` | Yes | ✅ Present |
| `version` | Recommended | ✅ Present |
| `description` | Recommended | ✅ Present |

**Validation: ✅ PASS**

---

## 2. Subagent Specification Validation

### Official Specification (from [Custom Subagents](https://code.claude.com/docs/en/sub-agents))

**File Location:**
- Project: `.claude/agents/agent-name.md`
- Personal: `~/.claude/agents/agent-name.md`
- Plugin: `<plugin>/agents/agent-name.md`

**Required Frontmatter Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (lowercase, hyphens) |
| `description` | Yes | When Claude should delegate to this agent |

**Optional Frontmatter Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `tools` | string/array | Tools the agent can use |
| `disallowedTools` | string/array | Tools to deny |
| `model` | string | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | string | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `skills` | array | Skills to preload |
| `hooks` | object | Lifecycle hooks |

### Our Proposed Agents

**ralph-data-layer.md:**
```yaml
---
name: ralph-data-layer                    ✅ Valid name format
description: Specialized agent for...     ✅ Required field
tools: Read, Write, Edit, Bash, Grep, Glob ✅ Valid tool list
model: sonnet                             ✅ Valid model alias
---
```

**Validation: ✅ PASS** - All proposed agents follow the spec.

### Corrections Needed

1. **File Location:** For plugin distribution, agents go in `agents/` at plugin root
2. **Hooks in Agents:** Only `PreToolUse`, `PostToolUse`, and `Stop` are supported in agent frontmatter

---

## 3. Skills Specification Validation

### Official Specification (from [Extend Claude with Skills](https://code.claude.com/docs/en/skills))

**File Structure:**
```
skill-name/
├── SKILL.md           # Required
├── template.md        # Optional
├── examples/          # Optional
└── scripts/           # Optional
```

**Required Frontmatter Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `name` | No (uses directory name) | Display name |
| `description` | Recommended | When to use this skill |

**Optional Frontmatter Fields:**
| Field | Description |
|-------|-------------|
| `argument-hint` | Hint for autocomplete |
| `disable-model-invocation` | Prevent Claude auto-invocation |
| `user-invocable` | Hide from `/` menu |
| `allowed-tools` | Tools Claude can use without asking |
| `model` | Model to use when active |
| `context` | Set to `fork` for subagent execution |
| `agent` | Which subagent type for `context: fork` |
| `hooks` | Scoped lifecycle hooks |

### Our Proposed Skills

**skills/create-prd/SKILL.md:**
```yaml
---
name: create-prd                          ✅ Valid
description: Create PRD for feature       ✅ Recommended field
---
```

**Validation: ✅ PASS** - Existing skills follow the spec.

### Enhancements Needed

1. **Add `disable-model-invocation: true`** to skills that should only be user-invoked (create-prd, design-solution, solution-to-stories)
2. **Consider `context: fork`** for research skills that should run in isolation
3. **Add `argument-hint`** for better autocomplete (e.g., `[feature-name]`)

---

## 4. Hooks Specification Validation

### Official Specification (from [Hooks Reference](https://code.claude.com/docs/en/hooks))

**Available Hook Events:**
| Event | When It Fires |
|-------|---------------|
| `SessionStart` | Session begins or resumes |
| `UserPromptSubmit` | User submits a prompt |
| `PreToolUse` | Before tool execution |
| `PermissionRequest` | When permission dialog appears |
| `PostToolUse` | After tool succeeds |
| `PostToolUseFailure` | After tool fails |
| `SubagentStart` | When spawning a subagent |
| `SubagentStop` | When subagent finishes |
| `Stop` | Claude finishes responding |
| `PreCompact` | Before context compaction |
| `Setup` | When `--init` or `--maintenance` flags used |
| `SessionEnd` | Session terminates |
| `Notification` | Claude Code sends notifications |

**Hook Configuration Format:**
```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",  // or "prompt" or "agent"
            "command": "your-command-here",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Hook Types:**
- `command` - Execute shell commands
- `prompt` - LLM evaluation (for Stop, SubagentStop, UserPromptSubmit, PreToolUse)
- `agent` - Agentic verifier with tools

### Our Proposed Hooks

**hooks/hooks.json (Stop hook):**
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Validation: ✅ PASS** - Follows the spec.

### Enhancements Recommended

1. **Add `SubagentStop` hook** for layer agent completion tracking
2. **Consider `prompt` type** for intelligent stop decisions:
```json
{
  "type": "prompt",
  "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Check if all tasks are complete."
}
```
3. **Add `SessionStart` hook** for checkpoint loading
4. **Add `PostToolUse` hooks** for quality gate verification

---

## 5. Exit Code Behavior

### Official Specification

| Exit Code | Behavior |
|-----------|----------|
| 0 | Success. stdout shown in verbose mode, JSON parsed for structured control |
| 2 | Blocking error. stderr fed back to Claude |
| Other | Non-blocking error. stderr shown in verbose mode |

### Our Implementation

Current stop-hook.sh uses:
- Exit 0 with JSON `{"decision": "block", "reason": "..."}` for continue
- Exit 0 without JSON for allow stop

**Validation: ✅ PASS** - But should add error handling with exit code 2.

---

## 6. Prompt-Based Hooks (NEW - Recommended)

### Official Specification

Prompt hooks use Haiku LLM for context-aware decisions:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if Claude should stop: $ARGUMENTS...",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Response Schema:**
```json
{
  "ok": true | false,
  "reason": "Explanation"
}
```

### Recommendation

Replace bash-based stop-hook with prompt-based hook for more intelligent story completion detection.

---

## 7. Summary of Required Changes

### Critical (Must Fix)

| Item | Current | Required |
|------|---------|----------|
| Plugin structure | `.claude/agents/` | Move to `agents/` at plugin root |
| Agent location | Project-level | Plugin-level for distribution |

### Recommended Improvements

| Item | Enhancement |
|------|-------------|
| Skills | Add `disable-model-invocation: true` for user-only skills |
| Skills | Add `argument-hint` for better autocomplete |
| Hooks | Use `prompt` type for Stop hooks (smarter decisions) |
| Hooks | Add `SubagentStop` for layer agent tracking |
| Hooks | Add `SessionStart` for checkpoint loading |
| Error handling | Add exit code 2 handling for blocking errors |

### New Capabilities to Add

| Feature | Spec Support |
|---------|--------------|
| Prompt-based hooks | ✅ Supported (use `type: "prompt"`) |
| Agent hooks | ✅ Supported (`PreToolUse`, `PostToolUse`, `Stop` in agent frontmatter) |
| Skill preloading | ✅ Supported (`skills` field in agent frontmatter) |
| Permission modes | ✅ Supported (`permissionMode` field) |

---

## 8. Updated Agent Template (Spec-Compliant)

```markdown
---
name: ralph-data-layer
description: Specialized agent for database layer stories - migrations, models, queries, RLS policies. Use for data-layer INVEST stories in Ralph workflow.
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
model: sonnet
permissionMode: acceptEdits
skills:
  - database-patterns
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate-migration.sh"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/run-typecheck.sh"
---

# Data Layer Specialist

You are a database and data model specialist for the Ralph workflow.

## Expertise
- Supabase/PostgreSQL migrations
- TypeScript type generation
- Query optimization
- RLS policies

## Constraints (from CLAUDE.md)
- Always use `createClient()` for server components
- Always use `createBuildClient()` for generateStaticParams
- Generate types after schema changes
- Follow existing migration naming conventions

## Definition of Done
- [ ] Migration file created (if schema changes)
- [ ] Types regenerated
- [ ] Query functions typed correctly
- [ ] RLS policies applied (if needed)
- [ ] Build passes
```

---

## 9. Updated Skills Template (Spec-Compliant)

```markdown
---
name: create-prd
description: Create comprehensive Product Requirements Document with mandatory research phases. Use when starting a new feature that requires PRD documentation.
argument-hint: [feature-name]
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, WebFetch
---

# Create PRD (Product Requirements Document)

## Purpose
Create a comprehensive PRD following industry best practices...

## Phase 1: Research (MANDATORY)
...
```

---

## 10. Conclusion

The proposed ralph-workflow enhancements are **largely compatible** with official Claude Code specifications. Key adjustments needed:

1. **Move agents to plugin root** for proper plugin distribution
2. **Add recommended frontmatter fields** to skills and agents
3. **Consider prompt-based hooks** for more intelligent decisions
4. **Add SessionStart/SubagentStop hooks** for better orchestration

All proposed features (layer agents, orchestrator, parallel execution, quality gates) are fully supported by the Claude Code specification.
