# Ralph-Workflow Agent/Subagent Research

> **Research Date:** 2025-01-28 | **Status:** Recommendation Ready

## Executive Summary

Based on research into Claude Code's Task tool, Agent SDK, and Anthropic's multi-agent patterns, ralph-workflow should incorporate a **custom subagent architecture** to enable:
- Parallel story execution with context isolation
- Specialized agents for different story layers
- Orchestrator pattern for coordinated execution

---

## Key Research Findings

### 1. Claude Code's Built-in Subagent System

Claude Code includes built-in subagents that Claude automatically uses:

| Subagent | Purpose | When Used |
|----------|---------|-----------|
| **Explore** | Fast, read-only codebase analysis | Research phases, context gathering |
| **Plan** | Research for plan mode | Design/planning phases |
| **General-purpose** | Complex multi-step tasks | Tasks requiring exploration + action |

**Key Insight:** Subagents use isolated context windows and only return relevant summaries, preserving main agent context.

### 2. Custom Subagent Creation

Custom subagents are defined in Markdown files with YAML frontmatter in `.claude/agents/`:

```markdown
---
name: my-custom-agent
description: What this agent does
tools:
  - Read
  - Write
  - Edit
  - Bash
---

# System Prompt

Instructions for the specialized agent...
```

### 3. Anthropic's Orchestrator-Worker Pattern

From [Anthropic's multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system):

> "The lead agent decomposes queries into subtasks and describes them to subagents. Each subagent needs an objective, an output format, guidance on the tools and sources to use, and clear task boundaries."

**Architecture:**
```
┌─────────────────┐
│   Orchestrator  │
│   (Lead Agent)  │
└────────┬────────┘
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
│Worker1│ │Worker2│ │Worker3│ │Worker4│
└───────┘ └───────┘ └───────┘ └───────┘
```

### 4. Parallel Execution Best Practices

From [Claude Code subagent best practices](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/):

**When to Parallelize:**
- Tasks are **disjoint** (different modules/files)
- Tasks are **non-destructive**
- Tasks have **no dependencies** on each other

**When to Serialize:**
- High-risk operations
- Sequential dependencies
- Shared state modifications

### 5. Limitations to Consider

From [Claude Code docs](https://code.claude.com/docs/en/sub-agents):

1. **No nested subagents** - Subagents cannot spawn other subagents
2. **No real-time visibility** - Subagents execute immediately without stepwise output
3. **Context isolation** - Subagents can't share information between themselves
4. **Usage limits** - Each subagent counts toward API usage

---

## Recommended Architecture for Ralph-Workflow

### Layer-Specialized Subagents

Create 4 specialized subagents aligned with the 4-layer architecture:

```
.claude/agents/
├── ralph-data-layer.md      # Database, migrations, models
├── ralph-service-layer.md   # Business logic, domain services
├── ralph-api-layer.md       # Routes, controllers, validation
└── ralph-ui-layer.md        # Components, pages, styling
```

#### 1. Data Layer Agent (Spec-Compliant)

> Per [Claude Code Subagents Spec](https://code.claude.com/docs/en/sub-agents): Agents support `tools`, `model`, `permissionMode`, `skills`, and `hooks` in frontmatter.

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
hooks:
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

## Constraints
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

#### 2. Service Layer Agent (Spec-Compliant)

```markdown
---
name: ralph-service-layer
description: Specialized agent for business logic - domain services, utilities, transformations. Use for service-layer INVEST stories in Ralph workflow.
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
model: sonnet
permissionMode: acceptEdits
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/run-tests.sh"
---

# Service Layer Specialist

You are a business logic specialist for the Ralph workflow.

## Expertise
- Domain logic implementation
- Data transformations
- Utility functions
- Type-safe interfaces

## Constraints
- Follow existing patterns in lib/
- Maintain separation of concerns
- Use Zod for validation
- Export from index files

## Definition of Done
- [ ] Service/utility functions implemented
- [ ] Types exported
- [ ] Unit tests written
- [ ] No circular dependencies
- [ ] Build passes
```

#### 3. API Layer Agent (Spec-Compliant)

```markdown
---
name: ralph-api-layer
description: Specialized agent for API routes - handlers, validation, responses. Use for API-layer INVEST stories in Ralph workflow (Next.js App Router).
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
model: sonnet
permissionMode: acceptEdits
hooks:
  PreToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate-api-route.sh"
---

# API Layer Specialist

You are an API specialist for the Ralph workflow (Next.js App Router).

## Expertise
- Route handlers (app/api/)
- Zod validation schemas
- Error handling patterns
- Response formatting

## Constraints
- Validate all inputs with Zod
- Use existing error response patterns
- Follow REST conventions
- Maintain state restriction compliance (NY, CA, FL only)

## Definition of Done
- [ ] Route handler implemented
- [ ] Zod schema created/updated
- [ ] Error cases handled
- [ ] Response types correct
- [ ] Build passes
```

#### 4. UI Layer Agent (Spec-Compliant)

```markdown
---
name: ralph-ui-layer
description: Specialized agent for UI components - React Server Components, Tailwind CSS, accessibility. Use for UI-layer INVEST stories in Ralph workflow.
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
model: sonnet
permissionMode: acceptEdits
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/run-lint.sh"
---

# UI Layer Specialist

You are a UI/UX specialist for the Ralph workflow.

## Expertise
- React Server Components
- Tailwind CSS (Terroir Palette)
- Accessibility (a11y)
- Responsive design

## Constraints
- Use Terroir Palette colors only (piedmont-brown, ash-grey, calcified-chalk, wine-stave, slavonian-oak)
- Follow existing component patterns
- Return null for missing optional data (C-5)
- Accept className prop for composition (C-6)

## Definition of Done
- [ ] Component renders correctly
- [ ] Responsive on mobile/desktop
- [ ] Accessible (semantic HTML, ARIA)
- [ ] Uses design system colors
- [ ] Build passes
```

### Orchestrator Subagent (Spec-Compliant)

> Per [Claude Code Subagents Spec](https://code.claude.com/docs/en/sub-agents): The orchestrator uses `Task` tool to delegate to specialized agents. Subagents cannot spawn other subagents, so orchestration must be done from main session or via skill with `context: fork`.

```markdown
---
name: ralph-orchestrator
description: Master orchestrator that coordinates layer-specialized agents for story execution. Use when executing Ralph workflow stories that span multiple architectural layers.
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Task
model: opus
permissionMode: bypassPermissions
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: "Evaluate if the orchestrator should stop: $ARGUMENTS. Check if all stories are complete, all quality gates passed, and checkpoint is updated."
          timeout: 30
---

# Ralph Story Orchestrator

You are the master orchestrator for Ralph workflow story execution.

## Role
1. Read the story from the stories.json file
2. Analyze which layers are involved
3. Delegate to specialized layer agents via Task tool
4. Verify integration between layers
5. Run quality gates
6. Report completion status and update checkpoint

## Delegation Strategy

For each story:
1. Parse `layer` field from story metadata
2. Invoke appropriate layer agent(s) via Task tool:
   - `subagent_type: "ralph-data-layer"` for data stories
   - `subagent_type: "ralph-service-layer"` for service stories
   - `subagent_type: "ralph-api-layer"` for API stories
   - `subagent_type: "ralph-ui-layer"` for UI stories
3. Wait for completion
4. Verify cross-layer integration
5. Run post-story quality gates

## Parallel Execution Rules
- Parallelize: Independent stories touching different files
- Serialize: Stories with `depends_on` relationships
- Never: Parallel writes to same file

## Definition of Done
- [ ] All layer agents completed successfully
- [ ] Build passes (`npm run build`)
- [ ] Tests pass (`npm test`)
- [ ] Story marked complete in checkpoint.json
- [ ] Git commit created for story
```

### Parallel Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Ralph Orchestrator                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │ STORY-001 │   │ STORY-002 │   │ STORY-003 │
    │  (Data)   │   │ (Service) │   │   (UI)    │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │ralph-data │   │ralph-svc  │   │ralph-ui   │
    │  -layer   │   │  -layer   │   │  -layer   │
    └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
                    ┌───────────┐
                    │Integration│
                    │   Check   │
                    └───────────┘
```

---

## Integration with Existing Ralph-Workflow

### Phase 1: Add Agent Definitions

```bash
# Create agent directory
mkdir -p .claude/agents

# Add layer-specialized agents
touch .claude/agents/ralph-data-layer.md
touch .claude/agents/ralph-service-layer.md
touch .claude/agents/ralph-api-layer.md
touch .claude/agents/ralph-ui-layer.md
touch .claude/agents/ralph-orchestrator.md
```

### Phase 2: Modify Story Schema

Add `execution_strategy` to stories.json:

```json
{
  "story_id": "STORY-005",
  "layer": "ui",
  "execution_strategy": {
    "agent": "ralph-ui-layer",
    "parallel_with": ["STORY-006"],
    "model": "sonnet"
  }
}
```

### Phase 3: Update Orchestrator Script

Modify `ralph-orchestrator.sh` to use Task tool for delegation:

```bash
execute_story_with_agent() {
  local story_id="$1"
  local agent_type="$2"
  local story_prompt="$3"

  # Use Task tool pattern for subagent invocation
  claude --print "Use the Task tool with subagent_type=$agent_type to execute: $story_prompt"
}
```

---

## Cost Considerations

| Agent Type | Model | Input/1K | Output/1K | Use Case |
|------------|-------|----------|-----------|----------|
| Orchestrator | Opus | $0.015 | $0.075 | Coordination, complex decisions |
| Layer Agents | Sonnet | $0.003 | $0.015 | Structured implementation |
| Quick Tasks | Haiku | $0.00025 | $0.00125 | Validation, simple checks |

**Estimated per-story cost:**
- Orchestrator: ~$0.10-0.20 (reasoning + delegation)
- Layer Agent: ~$0.05-0.15 (implementation)
- Quality Gates: ~$0.01 (validation)
- **Total:** ~$0.16-0.36 per story

---

## Recommended Implementation Order

| Priority | Task | Effort |
|----------|------|--------|
| P0 | Create 4 layer-specialized agents | Low |
| P0 | Create orchestrator agent | Medium |
| P1 | Update story schema for agent selection | Low |
| P1 | Modify orchestrator.sh for Task delegation | Medium |
| P2 | Add parallel execution support | High |
| P3 | Add model selection per story complexity | Low |

---

## Sources

- [Claude Code Custom Subagents](https://code.claude.com/docs/en/sub-agents)
- [Task Tool: Claude Code's Agent Orchestration](https://dev.to/bhaidar/the-task-tool-claude-codes-agent-orchestration-system-4bf2)
- [Anthropic Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Best Practices for Claude Code Subagents](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/)
- [Anthropic Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [Claude Agent SDK Subagents](https://platform.claude.com/docs/en/agent-sdk/subagents)
- [Claude Code Swarm Orchestration](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
