# Ralph-Workflow Enhancement Roadmap

> **Status:** Planned | **Version:** 2.1.0 | **Last Updated:** 2025-01-28

## Executive Summary

Transform ralph-workflow from a sequential story executor into a production-grade agentic orchestration system with checkpoint/resume, parallel execution, observability, and learning capabilities.

---

## Table of Contents

1. [Phase 1: Core Orchestrator Enhancements](#phase-1-core-orchestrator-enhancements)
2. [Phase 2: Skills & Templates Enhancements](#phase-2-skills--templates-enhancements)
3. [Phase 3: Observability & Integration](#phase-3-observability--integration)
4. [Phase 4: Agent/Subagent Architecture](#phase-4-agentsubagent-architecture)
5. [Implementation Order](#implementation-order)
6. [Directory Structure](#directory-structure)
7. [Success Criteria](#success-criteria)

---

## Phase 1: Core Orchestrator Enhancements

### 1.1 Checkpoint/Resume System

**Purpose:** Enable resuming execution after crashes, interruptions, or context window exhaustion.

**Files:**
- `scripts/lib/checkpoint.sh` (NEW)
- `scripts/ralph-orchestrator.sh` (MODIFY)
- `ralph/state/checkpoint.json` (RUNTIME)

**Checkpoint Schema:**
```json
{
  "version": "1.0",
  "feature": "provenance-engine",
  "started_at": "2025-01-28T10:00:00Z",
  "last_updated": "2025-01-28T12:30:00Z",
  "current_story_id": "STORY-005",
  "stories": {
    "STORY-001": { "status": "completed", "iterations": 3, "cost_usd": 0.42 },
    "STORY-002": { "status": "completed", "iterations": 2, "cost_usd": 0.31 },
    "STORY-005": { "status": "in_progress", "iterations": 1, "cost_usd": 0.15 }
  },
  "total_cost_usd": 0.88,
  "budget_limit_usd": 10.00
}
```

### 1.2 Retry Strategies

**Purpose:** Handle transient failures with configurable retry behavior.

**Files:**
- `scripts/lib/retry.sh` (NEW)

**Strategies:**
| Strategy | Delay Pattern | Use Case |
|----------|--------------|----------|
| immediate | 0s, 0s, 0s | Transient failures |
| linear | 5s, 10s, 15s | Rate limiting |
| exponential | 5s, 25s, 125s | API overload |

### 1.3 Parallel Execution with Git Worktrees

**Purpose:** Execute independent stories concurrently for faster completion.

**Files:**
- `scripts/lib/parallel.sh` (NEW)
- `scripts/ralph-orchestrator.sh` (MODIFY)

**Approach:** Use git worktrees to create isolated environments for parallel story execution, then merge results.

### 1.4 Cost Tracking

**Purpose:** Monitor API costs and enforce budgets.

**Files:**
- `scripts/lib/cost.sh` (NEW)

**Token-to-Cost Mapping:**
```
Claude Opus: $0.015/1K input, $0.075/1K output
Claude Sonnet: $0.003/1K input, $0.015/1K output
```

---

## Phase 2: Skills & Templates Enhancements

### 2.1 Pluggable Architecture Templates

**Purpose:** Support different codebase architectures beyond 4-layer.

**Files:**
- `templates/architectures/registry.json` (NEW)
- `templates/architectures/layered-4/` (NEW)
- `templates/architectures/microservices/` (NEW)
- `templates/architectures/serverless/` (NEW)
- `templates/architectures/event-driven/` (NEW)

**Architectures:**
- **layered-4:** Traditional Data → Service → API → UI
- **microservices:** Service mesh, API gateway, distributed services
- **serverless:** Functions, events, storage, API
- **event-driven:** Event bus, handlers, projections

### 2.2 Learning Mechanism

**Purpose:** Extract and reuse patterns from successful stories.

**Files:**
- `patterns/registry.json` (NEW)
- `patterns/learned/` (NEW)
- `scripts/lib/patterns.sh` (NEW)

**Pattern Schema:**
```json
{
  "id": "supabase-server-client",
  "category": "database",
  "trigger": "supabase AND server component",
  "solution": "Use createClient() from lib/supabase/server.ts",
  "anti_pattern": "Using createBuildClient() in server components",
  "source": "provenance-engine/STORY-001",
  "confidence": 0.95
}
```

### 2.3 Quality Gates

**Purpose:** Enforce code quality at key checkpoints.

**Files:**
- `scripts/lib/quality-gates.sh` (NEW)
- `config/quality-gates.yaml` (NEW)

**Gates:**
- **pre-story:** Dependencies check, branch clean
- **post-story:** Build passes, tests pass, no type errors
- **pre-merge:** All stories complete, integration tests

### 2.4 Modular Research Sub-Skills

**Purpose:** Make research phases independently invocable.

**Files:**
- `skills/research/codebase-patterns/SKILL.md` (NEW)
- `skills/research/database/SKILL.md` (NEW)
- `skills/research/ui-ux/SKILL.md` (NEW)

---

## Phase 3: Observability & Integration

### 3.1 Structured JSON Logging

**Purpose:** Enable debugging and analysis with structured logs.

**Files:**
- `scripts/lib/logger.sh` (NEW)
- `ralph/logs/` (RUNTIME)

**Log Format:**
```json
{
  "timestamp": "2025-01-28T12:30:45.123Z",
  "level": "INFO",
  "component": "orchestrator",
  "story_id": "STORY-005",
  "iteration": 3,
  "message": "Story completed successfully",
  "duration_ms": 45000,
  "tokens": { "input": 12000, "output": 3500 },
  "cost_usd": 0.089
}
```

### 3.2 Metrics Collection

**Purpose:** Track performance and quality metrics across runs.

**Files:**
- `scripts/lib/metrics.sh` (NEW)
- `ralph/metrics/` (RUNTIME)

**Metrics:**
- Story completion rates
- Average iterations per story
- Token usage and costs
- Duration statistics

### 3.3 Webhook Integration

**Purpose:** Real-time notifications to external systems.

**Files:**
- `scripts/lib/webhooks.sh` (NEW)
- `config/webhooks.yaml` (NEW)

**Supported:**
- Slack
- Discord
- Generic HTTP webhooks

### 3.4 CI/CD Integration

**Purpose:** Enable automated execution in CI pipelines.

**Files:**
- `.github/workflows/ralph-execute.yml` (NEW)

### 3.5 Error Handling Improvements

**Purpose:** Better error classification and recovery.

**Files:**
- `hooks/stop-hook.sh` (MODIFY)

**Error Types:**
- RATE_LIMITED → Retry after delay
- TIMEOUT → Retry immediately
- TYPE_ERROR → Human intervention
- BUILD_FAILED → Human intervention

---

## Phase 4: Agent/Subagent Architecture

> See detailed research in [AGENTS_RESEARCH.md](./AGENTS_RESEARCH.md)

### 4.1 Layer-Specialized Subagents

**Purpose:** Create specialized agents for each architectural layer to improve context focus and execution quality.

**Files:**
- `.claude/agents/ralph-data-layer.md` (NEW)
- `.claude/agents/ralph-service-layer.md` (NEW)
- `.claude/agents/ralph-api-layer.md` (NEW)
- `.claude/agents/ralph-ui-layer.md` (NEW)

**Agent Specializations:**

| Agent | Layer | Expertise | Model |
|-------|-------|-----------|-------|
| `ralph-data-layer` | Data | Migrations, queries, types, RLS | Sonnet |
| `ralph-service-layer` | Service | Business logic, transformations | Sonnet |
| `ralph-api-layer` | API | Routes, validation, responses | Sonnet |
| `ralph-ui-layer` | UI | Components, styling, a11y | Sonnet |

### 4.2 Orchestrator Subagent

**Purpose:** Master agent that delegates to layer specialists and coordinates execution.

**Files:**
- `.claude/agents/ralph-orchestrator.md` (NEW)

**Responsibilities:**
1. Parse story layer assignments
2. Delegate to appropriate layer agents via Task tool
3. Coordinate parallel execution for independent stories
4. Verify cross-layer integration
5. Run quality gates between stories

### 4.3 Story Schema Updates

**Purpose:** Extend stories.json to support agent-based execution.

**New Fields:**
```json
{
  "story_id": "STORY-005",
  "layer": "ui",
  "execution_strategy": {
    "agent": "ralph-ui-layer",
    "parallel_with": ["STORY-006", "STORY-007"],
    "model": "sonnet",
    "timeout_minutes": 15
  }
}
```

### 4.4 Parallel Agent Execution

**Purpose:** Execute independent stories concurrently using subagent parallelization.

**Rules:**
- **Parallelize:** Stories touching different files/modules
- **Serialize:** Stories with `depends_on` relationships
- **Never:** Parallel writes to same file

**Flow:**
```
┌─────────────────┐
│   Orchestrator  │
└────────┬────────┘
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
│Data   │ │Service│ │API    │ │UI     │
│Agent  │ │Agent  │ │Agent  │ │Agent  │
└───────┘ └───────┘ └───────┘ └───────┘
```

### 4.5 Cost Optimization via Model Selection

**Purpose:** Use appropriate model tier per task complexity.

| Task Type | Model | Cost/1K tokens |
|-----------|-------|----------------|
| Orchestration, complex reasoning | Opus | $0.015 input, $0.075 output |
| Standard implementation | Sonnet | $0.003 input, $0.015 output |
| Validation, simple checks | Haiku | $0.00025 input, $0.00125 output |

**Estimated Savings:** 40-60% cost reduction vs. Opus-only execution

---

## Implementation Order

| Priority | Component | Effort | Dependencies |
|----------|-----------|--------|--------------|
| P0 | Checkpoint/Resume | Medium | None |
| P0 | Cost Tracking | Low | None |
| P0 | Structured Logging | Low | None |
| P0 | Error Handling | Low | None |
| **P0** | **Layer-Specialized Agents** | **Low** | **None** |
| P1 | Retry Strategies | Low | None |
| P1 | Quality Gates | Medium | None |
| P1 | Metrics Collection | Medium | Logging |
| **P1** | **Orchestrator Agent** | **Medium** | **Layer Agents** |
| **P1** | **Story Schema Updates** | **Low** | **None** |
| P2 | Webhook Integration | Medium | Logging |
| P2 | Architecture Templates | High | None |
| **P2** | **Parallel Agent Execution** | **High** | **Orchestrator** |
| P3 | Parallel Execution (Git) | High | Checkpoint |
| P3 | Learning Mechanism | High | Logging, Metrics |
| P3 | Modular Research | Medium | None |
| P3 | CI/CD Integration | Medium | All P0-P1 |
| **P3** | **Model Selection** | **Low** | **Orchestrator** |

---

## Directory Structure

```
ralph-workflow/
├── .claude/
│   └── agents/                    # NEW: Layer-specialized subagents
│       ├── ralph-orchestrator.md
│       ├── ralph-data-layer.md
│       ├── ralph-service-layer.md
│       ├── ralph-api-layer.md
│       └── ralph-ui-layer.md
├── scripts/
│   ├── lib/
│   │   ├── checkpoint.sh
│   │   ├── retry.sh
│   │   ├── parallel.sh
│   │   ├── cost.sh
│   │   ├── logger.sh
│   │   ├── metrics.sh
│   │   ├── webhooks.sh
│   │   ├── quality-gates.sh
│   │   └── patterns.sh
│   ├── ralph-orchestrator.sh
│   ├── ralph-full-pipeline.sh
│   └── ralph-loop.sh
├── hooks/
│   ├── stop-hook.sh
│   └── hooks.json
├── skills/
│   ├── create-prd/
│   ├── design-solution/
│   ├── solution-to-stories/
│   └── research/
│       ├── codebase-patterns/
│       ├── database/
│       └── ui-ux/
├── templates/
│   ├── architectures/
│   │   ├── registry.json
│   │   ├── layered-4/
│   │   ├── microservices/
│   │   └── serverless/
│   └── [existing templates]
├── patterns/
│   ├── registry.json
│   └── learned/
├── config/
│   ├── quality-gates.yaml
│   └── webhooks.yaml
└── .github/
    └── workflows/
        └── ralph-execute.yml
```

---

## Success Criteria

1. **Checkpoint/Resume:** Orchestrator can resume from any story after crash
2. **Cost Visibility:** Every run produces cost breakdown per story
3. **Observability:** Structured logs enable debugging and analysis
4. **Quality Assurance:** Gates prevent broken code from progressing
5. **Notifications:** Team receives real-time status via webhooks
6. **CI/CD Ready:** Workflow can execute in GitHub Actions
7. **Agent Specialization:** Layer agents execute stories with focused context
8. **Parallel Agents:** Independent stories execute concurrently via subagents
9. **Model Optimization:** Cost reduced 40-60% via appropriate model selection

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Parallel execution merge conflicts | Separate branches, careful merge |
| Cost tracking inaccuracy | Conservative estimates, headroom |
| Webhook secrets exposure | Environment variables only |
| Learning mechanism noise | Confidence thresholds, review |
