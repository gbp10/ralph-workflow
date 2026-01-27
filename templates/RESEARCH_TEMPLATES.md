# Research Templates for /design-solution

This document provides templates for the 9 mandatory research areas investigated during the solution design phase.

---

## Research Area Templates

### 1. Codebase Patterns (`codebase-patterns.md`)

```markdown
# Codebase Patterns: [Feature Name]

## Investigation Scope
- Similar features examined: [list]
- Directories searched: [list]
- Patterns identified: [list]

## Findings

### Naming Conventions
- Files: [pattern, e.g., `PascalCase.ts` for components]
- Functions: [pattern, e.g., `camelCase` for methods]
- Classes: [pattern]

### Code Organization
- Feature location: [where similar features live]
- Test location: [where tests are placed]
- Shared utilities: [common helpers used]

### Design Patterns Used
| Pattern | Location | Usage |
|---------|----------|-------|
| [Repository] | `src/repositories/` | Data access |
| [Service] | `src/services/` | Business logic |

## Constraints Discovered
- [ ] Must follow [pattern X] for consistency
- [ ] Must use [utility Y] for [purpose]

## Open Questions
- [Question that needs clarification]
```

---

### 2. Architecture Mapping (`architecture.md`)

```markdown
# Architecture Mapping: [Feature Name]

## Investigation Scope
- Architecture docs reviewed: [list]
- Module boundaries traced: [list]

## System Overview
[Brief description of overall architecture]

## Module Boundaries
| Module | Responsibility | Dependencies |
|--------|---------------|--------------|
| [Module A] | [What it does] | [What it depends on] |

## Where This Feature Fits
- **Primary Module:** [module name]
- **Justification:** [why it belongs here]
- **Interactions:** [which modules it will interact with]

## Constraints Discovered
- [ ] Must not create circular dependency with [module]
- [ ] Must respect [boundary]

## Open Questions
- [Architectural question]
```

---

### 3. Database/Data Model (`database.md`)

```markdown
# Database/Data Model: [Feature Name]

## Investigation Scope
- Schema files reviewed: [list]
- Migrations examined: [list]
- Related entities: [list]

## Existing Schema

### Relevant Tables
| Table | Purpose | Key Fields |
|-------|---------|------------|
| [users] | [User accounts] | id, email, role |

### Entity Relationships
```
[Entity A] --< [Entity B] (one-to-many)
[Entity B] >-- [Entity C] (many-to-one)
```

## Migration Patterns
- Migration tool: [e.g., TypeORM, Prisma, Alembic]
- Naming convention: [e.g., `YYYYMMDD_description.ts`]
- Rollback approach: [how rollbacks work]

## Constraints Discovered
- [ ] Must use [migration tool]
- [ ] Must maintain backwards compatibility with [table]
- [ ] [Field X] has constraint [Y]

## Open Questions
- [Database question]
```

---

### 4. API Surface (`api-surface.md`)

```markdown
# API Surface: [Feature Name]

## Investigation Scope
- Route files examined: [list]
- OpenAPI/Swagger specs: [location]
- Related endpoints: [list]

## Existing Endpoints

### Related Routes
| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/users` | List users | JWT |
| POST | `/api/v1/users` | Create user | JWT + Admin |

### Request/Response Patterns
```json
// Standard success response
{
  "data": { ... },
  "meta": { "page": 1, "total": 100 }
}

// Standard error response
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "...",
    "details": [...]
  }
}
```

## API Conventions
- Versioning: [e.g., `/api/v1/`]
- Authentication: [e.g., JWT in Authorization header]
- Pagination: [e.g., `?page=1&limit=20`]

## Constraints Discovered
- [ ] Must follow REST conventions at [path pattern]
- [ ] Must use [middleware] for auth
- [ ] Must return errors in [format]

## Open Questions
- [API question]
```

---

### 5. Dependency Analysis (`dependencies.md`)

```markdown
# Dependency Analysis: [Feature Name]

## Investigation Scope
- Package manifests: [package.json, requirements.txt, etc.]
- External service calls: [traced from code]

## Package Dependencies

### Relevant Packages
| Package | Version | Purpose |
|---------|---------|---------|
| [axios] | ^1.4.0 | HTTP client |

### Peer Dependencies
[Any peer dependency considerations]

## External Services

### Service Integrations
| Service | Type | Usage |
|---------|------|-------|
| [Stripe] | REST API | Payment processing |
| [SendGrid] | REST API | Email delivery |

### Integration Patterns
- HTTP client used: [e.g., axios, fetch]
- Retry strategy: [e.g., exponential backoff]
- Circuit breaker: [yes/no, implementation]

## Constraints Discovered
- [ ] Must use existing [HTTP client] instance
- [ ] Must follow [retry pattern] for external calls

## Open Questions
- [Dependency question]
```

---

### 6. Security Constraints (`security.md`)

```markdown
# Security Constraints: [Feature Name]

## Investigation Scope
- Auth middleware: [files examined]
- Security policies: [docs reviewed]
- Data classification: [PII fields identified]

## Authentication

### Auth Mechanism
- Type: [JWT, Session, OAuth, etc.]
- Location: [header, cookie]
- Middleware: [file path]

### Authorization
| Role | Permissions |
|------|-------------|
| admin | Full access |
| user | Read own data |

## Data Sensitivity

### PII Fields
| Field | Classification | Protection |
|-------|---------------|------------|
| email | PII | Encrypted at rest |
| ssn | Sensitive PII | Encrypted + masked |

### Compliance Requirements
- [ ] GDPR considerations
- [ ] Data retention policies
- [ ] Audit logging requirements

## Constraints Discovered
- [ ] Must use [auth middleware]
- [ ] Must encrypt [field type] at rest
- [ ] Must log access to [sensitive data]

## Open Questions
- [Security question]
```

---

### 7. Performance Baselines (`performance.md`)

```markdown
# Performance Baselines: [Feature Name]

## Investigation Scope
- Metrics dashboards: [reviewed]
- SLA documentation: [reviewed]
- Load test results: [if available]

## Current Metrics

### Response Time SLAs
| Endpoint | P50 | P95 | P99 | SLA |
|----------|-----|-----|-----|-----|
| GET /users | 50ms | 150ms | 300ms | <500ms |

### Throughput
- Peak RPS: [number]
- Average RPS: [number]

## Known Bottlenecks
| Area | Issue | Impact |
|------|-------|--------|
| [Database] | [N+1 queries] | [Slow list views] |

## Resource Constraints
- Database connection pool: [size]
- Memory limits: [per service]
- Rate limits: [per endpoint]

## Constraints Discovered
- [ ] Must meet [SLA] for response time
- [ ] Must not exceed [N] database queries
- [ ] Must implement caching for [use case]

## Open Questions
- [Performance question]
```

---

### 8. Prior Art (`prior-art.md`)

```markdown
# Prior Art: [Feature Name]

## Investigation Scope
- Git history searched: [date range]
- Related PRs/issues: [reviewed]
- Technical debt tickets: [reviewed]

## Related Previous Work

### Similar Features
| Feature | PR/Commit | Learnings |
|---------|-----------|-----------|
| [User CRUD] | #123 | [Pattern established] |

### Relevant PRs
| PR | Title | Key Changes | Outcome |
|----|-------|-------------|---------|
| #456 | Add user roles | Role middleware | Merged |

### Failed Attempts
| Attempt | Why It Failed | Lessons |
|---------|---------------|---------|
| [Previous approach] | [Reason] | [What to avoid] |

## Technical Debt

### Known Issues in Area
| Issue | Impact | Workaround |
|-------|--------|------------|
| [Issue X] | [Impact] | [Current workaround] |

## Constraints Discovered
- [ ] Must address [tech debt] as part of this work
- [ ] Must avoid [previous mistake]

## Open Questions
- [Historical question]
```

---

### 9. UI/UX Analysis (`ui-ux/analysis.md`)

```markdown
# UI/UX Analysis: [Feature Name]

## Investigation Scope
- Screens captured: [count]
- Flows traced: [count]
- Components identified: [list]

## Screens Investigated

| Screen | Path | Screenshot | Key Observations |
|--------|------|------------|------------------|
| User List | /settings/users | `screens/01-user-list.png` | DataTable component, row actions |
| Create Form | /settings/users/new | `screens/02-create-form.png` | FormBuilder pattern |

## Flows Investigated

### Flow: [Flow Name]
- **Screenshots:** `flows/[flow-name]/`
- **Steps:**
  1. User clicks [action] on [screen]
  2. [Modal/Page] appears with [content]
  3. User completes [action]
  4. [Feedback] is shown

- **Patterns Observed:**
  - Navigation: [tabs, sidebar, breadcrumbs]
  - Forms: [inline validation, submit behavior]
  - Feedback: [toast, modal, inline message]

## UI Component Patterns

### Forms
- Component: [e.g., `FormBuilder` from `@/components/ui`]
- Validation: [inline, on-submit, or both]
- Error display: [below field, toast, summary]

### Tables
- Component: [e.g., `DataTable`]
- Features: [sorting, filtering, pagination]
- Row actions: [dropdown, inline buttons]

### Modals
- Component: [e.g., `Dialog` from `@/components/ui`]
- Sizes: [sm, md, lg]
- Close behavior: [X button, outside click, escape]

### Notifications
- Component: [e.g., `Toast`]
- Position: [top-right, bottom-center]
- Duration: [auto-dismiss, manual]

## Constraints Discovered
- [ ] Must use [component X] for forms
- [ ] Must follow [modal pattern] for confirmations
- [ ] Must show [feedback type] on success

## Open Questions
- [UI/UX question]
```

---

## Screenshot Directory Structure

```
research/ui-ux/
├── analysis.md
└── screenshots/
    ├── screens/
    │   ├── 01-[screen-name].png
    │   ├── 02-[screen-name].png
    │   └── ...
    ├── flows/
    │   └── [flow-name]/
    │       ├── step-01-[description].png
    │       ├── step-02-[description].png
    │       └── ...
    └── README.md
```

### README.md Template

```markdown
# Screenshots Index

## Screens
| File | Description | Captured |
|------|-------------|----------|
| `screens/01-user-list.png` | User list view with sample data | 2026-01-26 |

## Flows
### [Flow Name]
| Step | File | Description |
|------|------|-------------|
| 1 | `flows/create-user/step-01-dashboard.png` | Starting point |
| 2 | `flows/create-user/step-02-click-add.png` | Click add button |
```

---

## Research Synthesis Template

Save to: `.claude/ralph/specs/[feature]/research-synthesis.md`

```markdown
# Research Synthesis: [Feature Name]

## Executive Summary
[2-3 paragraphs summarizing key research findings and their implications]

## Conflicts & Resolutions

### Conflict 1: [Title]
- **Finding A:** [from research area X]
- **Finding B:** [from research area Y]
- **Tension:** [what conflicts]
- **Resolution:** [proposed approach]

## Gaps & Assumptions

### Gap 1: [What's Unknown]
- **Searched:** [which research areas]
- **Could not determine:** [specific information]
- **Assumption:** [what we're assuming]
- **Risk if wrong:** [impact]

## Consolidated Constraints

### From Codebase Patterns
- [Constraint 1]
- [Constraint 2]

### From Architecture
- [Constraint 1]

### From Security
- [Constraint 1]

### From UI/UX
- [Constraint 1]

## Key Insights
[Non-obvious discoveries that significantly impact solution design]

## Readiness Assessment
- [ ] All critical questions answered
- [ ] Assumptions documented and acceptable
- [ ] Constraints are clear and non-contradictory
- [ ] Ready to proceed to solution design
```
