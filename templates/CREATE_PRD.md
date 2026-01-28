# Skill: Create PRD (Product Requirements Document)

## Purpose
Create a comprehensive Product Requirements Document following industry best practices that can be converted to actionable user stories for Ralph Wiggum execution.

---

## ⚠️ CRITICAL: Mandatory Context-Gathering Phase

**Before writing ANY PRD content, you MUST complete this research phase.**

Without proper context gathering, the PRD will be based on assumptions, contaminating the entire Ralph workflow with incorrect information.

### Step 1: Codebase Research

```markdown
## Research Checklist

### 1.1 Find Related Code
- [ ] Use `Glob` to find files matching the feature domain
- [ ] Use `Grep` to search for related function names, classes, patterns
- [ ] Use `Read` to examine existing implementations

### 1.2 Understand Existing Patterns
- [ ] Identify similar features already implemented
- [ ] Note naming conventions, folder structure
- [ ] Document reusable services, utilities, base classes

### 1.3 Identify Integration Points
- [ ] What services will this feature interact with?
- [ ] What APIs are involved?
- [ ] What shared state or data stores?
```

**Example Research Commands:**
```bash
# Find related entities
Glob: "src/**/*Tracking*.ts"

# Search for existing patterns
Grep: "tracking" --type ts

# Read service implementations
Read: "src/services/TrackingService.ts"
```

### Step 2: Database Schema Research (If Applicable)

```markdown
### 2.1 Query Relevant Tables
- [ ] Connect to your database
- [ ] List tables in the domain
- [ ] Get column details

### 2.2 Understand Relationships
- [ ] Identify foreign keys and relationships
- [ ] Note lookup tables involved
- [ ] Document existing constraints

### 2.3 Check Data Volume
- [ ] Check row counts for performance considerations
```

### Step 3: Documentation Review

```markdown
### 3.1 Check Existing Specs
- [ ] Read existing specs for related features
- [ ] Read architecture documentation
- [ ] Check domain-specific skills

### 3.2 Review Knowledge Files
- [ ] Database schema docs
- [ ] Infrastructure docs
- [ ] Any domain-specific knowledge files
```

### Step 4: UI Research (If Applicable)

```markdown
### 4.1 Examine Current UI
- [ ] Navigate to relevant pages
- [ ] Take screenshots of current state
- [ ] Document user workflow (clicks, inputs, outputs)

### 4.2 Identify UI Components
- [ ] Find related views/templates
- [ ] Check JavaScript/TypeScript files
- [ ] Note CSS/styling patterns
```

### Step 5: Document Research Findings

Before proceeding to PRD, create a research summary:

```markdown
## Research Summary

### Codebase Findings
| Area | Files Found | Key Observations |
|------|-------------|------------------|
| Entities | [list] | [patterns noted] |
| Services | [list] | [existing logic] |
| Controllers | [list] | [API patterns] |
| Views | [list] | [UI patterns] |

### Database Findings
| Table | Columns | Rows | Relevance |
|-------|---------|------|-----------|
| [table] | [count] | [count] | [how it relates] |

### Existing Documentation
| Document | Path | Key Insights |
|----------|------|--------------|
| [name] | [path] | [what we learned] |

### UI Findings
| Page | URL | Current Behavior |
|------|-----|------------------|
| [name] | [url] | [description] |

### Open Questions from Research
- [ ] Question 1 (needs stakeholder input)
- [ ] Question 2 (needs technical decision)
```

---

## Industry Best Practices Applied

| Best Practice | Implementation |
|---------------|----------------|
| **Living Document** | Include change history, version tracking |
| **SMART Goals** | Specific, Measurable, Achievable, Relevant, Time-bound |
| **User-Centric** | Personas, scenarios, pain points before features |
| **Peer Review Early** | Engage design + engineering before finalizing |
| **Keep It Concise** | Link out for details, don't overstuff |
| **Connect to Customer Pain** | Every feature tied to a user problem |

---

## PRD Template

```markdown
# PRD: [Feature Name]

## Document Info
| Field | Value |
|-------|-------|
| **Author** | [Name] |
| **Created** | [Date] |
| **Last Updated** | [Date] |
| **Status** | Draft → Review → Approved |
| **Version** | 1.0 |
| **Reviewers** | [Engineering Lead], [Design Lead] |

## Change History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [Date] | [Name] | Initial draft |

---

## 1. Problem Statement

### What problem are we solving?
[Clear description of the problem. Who is affected? What's the impact?]

### Why now?
[Business context - why is this important to solve now?]

### Customer Pain Points
- **Pain 1:** [Description of user frustration]
- **Pain 2:** [Description of user frustration]

---

## 2. Target Users (Personas)

### Primary Persona
| Attribute | Description |
|-----------|-------------|
| **Role** | [e.g., Admin, User, Developer] |
| **Goals** | [What they're trying to accomplish] |
| **Pain Points** | [Current frustrations] |
| **Tech Comfort** | [Low / Medium / High] |

### Secondary Persona(s)
[If applicable]

---

## 3. User Scenarios

### Scenario 1: [Title]
**As a** [persona]
**I am** [situation/context]
**I want to** [action]
**So that** [outcome/benefit]

**Current Experience:** [How they do it today - the pain]
**Future Experience:** [How it will work with this feature]

### Scenario 2: [Title]
...

---

## 4. Goals & Success Metrics (SMART)

### Primary Goal
**Goal:** [Specific outcome]
**Metric:** [How we measure success]
**Target:** [Specific number/percentage]
**Timeline:** [When we expect to hit this]

### Secondary Goals
| Goal | Metric | Target | Timeline |
|------|--------|--------|----------|
| [Goal 1] | [Metric] | [Target] | [Date] |
| [Goal 2] | [Metric] | [Target] | [Date] |

---

## 5. Scope

### In Scope
- [Feature/capability 1]
- [Feature/capability 2]

### Out of Scope (Non-Goals)
- [What we're NOT building]
- [Future considerations - explicitly deferred]

### Assumptions
- [Assumption 1 - if false, impacts the plan]
- [Assumption 2]

### Constraints
- [Technical constraint]
- [Business constraint]
- [Timeline constraint]

---

## 6. User Stories

### Epic: [Epic Name]

#### US-001: [Title]
**As a** [persona]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria (Given/When/Then):**
- [ ] **Given** [precondition/context], **When** [action taken], **Then** [expected result]
- [ ] **Given** [precondition/context], **When** [action taken], **Then** [expected result]

**Priority:** P0 (Must Have) | P1 (Should Have) | P2 (Nice to Have)

**Estimated Execution Budget:** ~[X]K tokens
- Files to read: [list]
- Files to modify: [list]

---

### ✅ PASSING CRITERIA (Required for Each Story)

**A user story is ONLY complete when ALL of the following pass:**

#### Code Quality Gates
- [ ] Build succeeds - No compilation errors
- [ ] All tests pass (including new tests)
- [ ] No new warnings introduced

#### Database Layer (if applicable)
- [ ] Migration runs successfully (up and down)
- [ ] Schema matches specification
- [ ] Data integrity constraints enforced

#### Service Layer
- [ ] Unit tests cover happy path
- [ ] Unit tests cover error cases
- [ ] Unit tests cover edge cases
- [ ] Service methods return expected results

#### API Layer (if applicable)
- [ ] Endpoint returns correct status codes
- [ ] Response payload matches contract
- [ ] Authentication/authorization enforced
- [ ] Input validation working

#### UI Layer (if applicable)
- [ ] UI renders correctly
- [ ] User can complete the workflow
- [ ] Error messages display appropriately
- [ ] Responsive design maintained

#### Integration
- [ ] End-to-end flow works
- [ ] External service integrations handled (mock or real)

---

#### US-002: [Title]
...

---

## 7. Technical Design (High-Level)

### Architecture Impact
[Brief description of how this fits into existing architecture]

### Database Changes
| Change Type | Table/Column | Description |
|-------------|--------------|-------------|
| New Table | [TableName] | [Purpose] |
| New Column | [Table.Column] | [Purpose] |
| Migration | [Name] | [Description] |

### API Changes
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/[route] | [Purpose] |

### Service Layer
- [ ] New service: [ServiceName]
- [ ] Modified: [ServiceName] - [what changes]

### UI Changes
- [ ] New view: [ViewPath]
- [ ] Modified: [ViewPath] - [what changes]

---

## 8. Dependencies & Risks

### Dependencies
| Dependency | Type | Owner | Status |
|------------|------|-------|--------|
| [Dependency 1] | Internal/External | [Team/Person] | Resolved/Pending |

### Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [How we address it] |

---

## 9. Testing Strategy (Full-Stack Scope)

**CRITICAL:** Tests must cover ALL layers of the stack. Incomplete test coverage = incomplete feature.

### 9.1 Database Layer Tests
| Test | Query/Validation | Expected Result |
|------|------------------|-----------------|
| Schema validation | Check columns exist with correct types | Pass |
| Migration test | Run migration up/down | No errors, data preserved |

### 9.2 Service/Repository Layer Tests
| Test Class | Method | Test Cases |
|------------|--------|------------|
| [ServiceName]Tests | [MethodName] | Happy path, null input, invalid input, edge cases |

### 9.3 API/Controller Layer Tests
| Endpoint | Method | Test Cases | Expected Status |
|----------|--------|------------|-----------------|
| `/api/v1/[route]` | GET | Valid request | 200 OK |
| `/api/v1/[route]` | GET | Invalid ID | 404 Not Found |
| `/api/v1/[route]` | POST | Valid payload | 201 Created |
| `/api/v1/[route]` | POST | Invalid payload | 400 Bad Request |

### 9.4 UI/E2E Tests
| Test Scenario | Steps | Expected Outcome |
|---------------|-------|------------------|
| [User Flow 1] | 1. Navigate to X, 2. Click Y, 3. Fill Z | Visual confirmation, data saved |

### 9.5 Integration Tests
| Integration | Test | Validation |
|-------------|------|------------|
| DB + Service | Full CRUD cycle | Data persists correctly |
| Service + API | End-to-end request | Response matches expected |

---

## 10. Rollout Plan

| Phase | Environment | Scope | Duration | Success Criteria |
|-------|-------------|-------|----------|------------------|
| 1 | DEV | Full implementation | [X days] | Tests pass, code review |
| 2 | STG | Smoke testing | [X days] | No regressions |
| 3 | PROD | All users | Ongoing | Success metrics met |

### Rollback Plan
[How do we revert if something goes wrong?]

---

## 11. Open Questions

- [ ] [Question 1 - needs answer before implementation]
- [ ] [Question 2]

---

## Appendix

### Related Documents
- [Link to design mockups]
- [Link to existing specs]

### Knowledge Files to Update
- DATABASE_SCHEMA.md (if schema changes)
- INFRASTRUCTURE.md (if infra changes)

### Glossary
| Term | Definition |
|------|------------|
| [Term] | [Definition] |
```

---

## PRD Types

Choose the right format based on scope:

| Type | When to Use | Sections to Include |
|------|-------------|---------------------|
| **One-Pager** | Small features, < 3 user stories | Problem, Goals, User Stories, Acceptance Criteria |
| **Standard PRD** | Medium features, 3-8 user stories | All sections above |
| **Full PRD** | Large features, complex systems | All sections + detailed technical design, migration plans |

---

## Instructions for Claude

### ⚠️ CRITICAL: Research First, Write Second

**DO NOT write any PRD content until you have completed the mandatory context-gathering phase (see top of document).**

Without proper research, your PRD will be based on assumptions and will contaminate the entire Ralph workflow.

### Phase 1: Research (MANDATORY)
1. **Search codebase** - Use Glob, Grep, Read to find related code
2. **Query database** - Understand schema if applicable
3. **Read documentation** - Check existing specs and skills
4. **Examine UI** - If feature touches UI
5. **Document findings** - Create research summary before proceeding

### Phase 2: Clarify
1. **Ask clarifying questions** if scope is unclear after research
2. **Identify gaps** - What couldn't you find? What needs stakeholder input?
3. **Validate assumptions** - Confirm with user before proceeding

### Phase 3: Write PRD
1. **Start with the problem**, not the solution
2. **Connect every feature to a user pain point**
3. **Use SMART goals** for success metrics
4. **Estimate execution token budget** for each user story
5. **Define passing criteria** - Full-stack test requirements
6. **Keep it concise** - link out for details

### Phase 4: Review
1. **Recommend peer review** with engineering/design
2. **Save to** `ralph/specs/[feature-name]/requirements.md`
3. **Create companion files** if needed (design.md, tasks.md)

---

## Output Location

```
ralph/specs/[feature-name]/
├── requirements.md    # The PRD
├── design.md          # Detailed technical design (optional)
└── tasks.md           # Implementation checklist (optional)
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Instead Do |
|--------------|--------------|------------|
| Writing alone | Weak buy-in, missed requirements | Involve design + engineering early |
| Overstuffing | No one reads it | Keep concise, link out for details |
| Features without context | Team doesn't understand "why" | Connect to customer pain points |
| Static document | Becomes stale | Treat as living document, update regularly |
| Vague acceptance criteria | Can't verify completion | Use Given/When/Then format |

---

## Integration with Ralph Workflow

After PRD is approved:
1. **Convert to JSON:** Use `/prd-to-json` skill
2. **Estimate token budgets:** Each story scoped to fit context window
3. **Execute with Ralph:** Sequential story execution
4. **Update knowledge files:** When schema/infra changes
