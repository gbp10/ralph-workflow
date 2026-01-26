# Skill: Solution to Stories Converter

## Purpose
Convert an Implementation Blueprint into a JSON array of user stories that follow **industry best practices** and are scoped to fit within Claude's **context window** during execution.

---

## Blueprint Integration

> **IMPORTANT:** This skill now requires an Implementation Blueprint as input.

### Pre-requisites
Before running `/solution-to-stories`, ensure:
1. PRD exists at `.kiro/specs/[feature]/requirements.md`
2. `/design-solution` has been run
3. Blueprint exists at `.kiro/specs/[feature]/implementation-blueprint.md`

### Validation Checklist
```
□ Blueprint file exists
□ Blueprint has all 4 layer sections (Data, Service, API, UI)
□ Blueprint has "Constraints for Story Generation"
□ Research synthesis complete
```

### Constraint Flow
```
Blueprint Constraints → Story Acceptance Criteria
Blueprint Constraints → Story Prompt
Blueprint Suggested Files → Story file lists
Blueprint Sequencing → Story depends_on
Blueprint Layer → Story layer field
```

### New JSON Fields

The enhanced schema adds:
- `blueprint_path` - Reference to blueprint
- `blueprint_metadata` - Constraints and assumptions
- `story_groups` - Stories by architectural layer
- `execution_order` - Recommended sequence
- Per-story `layer` field
- Per-story `blueprint_reference`

---

## Part 1: User Story Best Practices

### 1.1 INVEST Criteria (MANDATORY)

Every user story MUST pass the INVEST validation before inclusion:

| Criterion | Question to Ask | Pass/Fail |
|-----------|-----------------|-----------|
| **I**ndependent | Can this story be developed without waiting for other stories? | Minimize dependencies |
| **N**egotiable | Is this open to discussion, not a rigid specification? | Allow implementation flexibility |
| **V**aluable | Does this deliver visible value to users or the business? | Not just technical refactoring |
| **E**stimable | Can the team estimate the effort required? | Clear enough scope |
| **S**mall | Does it fit within the token budget? | Split if too large |
| **T**estable | Can we write clear pass/fail tests for this? | Explicit acceptance criteria |

### 1.2 User Story Format

Use the canonical format in every story:

```
As a [user role],
I want [goal/capability],
So that [benefit/value].
```

**Example:**
```
As a dispatcher,
I want to see where each rate came from (Rate Agreement, RFP, or Default),
So that I can verify pricing accuracy and explain costs to clients.
```

### 1.3 Acceptance Criteria: Given/When/Then (Gherkin)

Replace simple checklists with **behavior-driven scenarios**:

```gherkin
Scenario: Rate from Rate Agreement includes source metadata
  Given a container with a matching Rate Agreement contract
  When I call GET /api/v1/pricing/snapshot/{id}
  Then the response includes sourceId = 1
  And the response includes contractId matching the contract

Scenario: Rate with no matching agreement returns Default source
  Given a container with no matching Rate Agreement
  When I call GET /api/v1/pricing/snapshot/{id}
  Then the response includes sourceId = 3
  And sourceDescription = "Default Rate"

Scenario: Unauthorized user receives 403
  Given a user without ViewCosts permission
  When I call GET /api/v1/pricing/snapshot/{id}
  Then the response status is 403 Forbidden
```

**Why Gherkin?**
- Human-readable AND machine-executable
- Forces thinking about preconditions and outcomes
- Directly translates to test cases

### 1.4 Definition of Done (Global)

Every story shares this Definition of Done checklist:

```
□ Code compiles/builds successfully
□ Unit tests pass with good coverage on new code
□ Integration tests pass (if applicable)
□ Code reviewed: PR approved or self-review documented
□ No security vulnerabilities: No hardcoded secrets, injection issues
□ Documentation updated: Comments, API docs, knowledge files
□ Acceptance criteria verified: All Given/When/Then scenarios pass
□ Regression check: Existing functionality unchanged
```

### 1.5 Edge Cases and Error Scenarios (Required)

Every story MUST include scenarios for:

1. **Happy Path** - Normal successful flow
2. **Error Handling** - What happens when things fail?
3. **Boundary Conditions** - Edge cases at limits
4. **Authorization** - Unauthorized access attempts
5. **Concurrency** - Simultaneous operations (if applicable)

**Example Error Scenarios:**
```gherkin
Scenario: Resource not found returns 404
  Given a non-existent id = 99999999
  When I call GET /api/v1/resource/99999999
  Then the response status is 404 Not Found
  And the response body includes error message

Scenario: Invalid input returns 400
  Given an id = "abc" (non-numeric)
  When I call GET /api/v1/resource/abc
  Then the response status is 400 Bad Request
```

### 1.6 Non-Functional Requirements (Per Story)

Include relevant NFRs for each story:

| Category | Example Requirement |
|----------|---------------------|
| **Performance** | API response < 500ms for 95th percentile |
| **Security** | Endpoint requires authentication |
| **Reliability** | Transaction rollback on partial failure |
| **Scalability** | Handles large data sets |
| **Accessibility** | UI components meet WCAG 2.1 AA (if applicable) |

### 1.7 Test Strategy (Per Story)

Specify which test types are required:

```json
"test_strategy": {
  "unit_tests": ["ServiceMethod_Scenario_ExpectedResult naming"],
  "integration_tests": ["API endpoint returns expected data"],
  "e2e_tests": ["If UI story: user can complete workflow"],
  "performance_tests": ["If critical path: response time < 500ms"],
  "regression_tests": ["Existing functionality still works"]
}
```

### 1.8 Rollback Plan (For Risky Stories)

For database migrations or breaking changes, include:

```json
"rollback_plan": {
  "database": "Migration includes rollback method",
  "feature_flag": "Use config to disable if needed",
  "revert_commit": "Single commit, easy to revert"
}
```

---

## Part 2: Token Budget Management

### 2.1 Critical Concept: Execution Token Budget

**The token limit is NOT about the story text size.** It's the **projected total tokens Claude will consume** while executing the task:

```
┌─────────────────────────────────────────────────────────────┐
│           Claude Context Window: ~100,000 tokens            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   System prompt & instructions        ~5,000 tokens         │
│   Knowledge files pre-loaded          ~10,000-15,000        │
│   Files read during task              ~15,000-40,000        │
│   Tool call outputs                   ~5,000-15,000         │
│   Conversation/iterations             ~5,000-15,000         │
│   Code generated                      ~5,000-10,000         │
│   ─────────────────────────────────────────────────         │
│   TOTAL EXECUTION BUDGET              < 100,000 tokens      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Token Budget Guidelines

| Story Complexity | Estimated Execution Budget | Safe Scope |
|------------------|---------------------------|------------|
| **Small** | ~20,000-35,000 tokens | 1-2 files, single method, minor change |
| **Medium** | ~40,000-55,000 tokens | 2-3 files, new service method, tests |
| **Large** | ~60,000-75,000 tokens | 3-5 files, new entity + migrations |
| **Maximum** | ~80,000 tokens | Leave 20K buffer for safety |

**Rule:** Never exceed ~80K projected tokens per story. If larger, split into sub-stories.

### 2.3 Token Estimation Formula

```
execution_tokens =
    system_prompt(~5,000) +
    knowledge_files(~15,000) +
    files_to_read(count × avg_file_size) +
    files_to_write(count × avg_code_size) +
    tool_outputs(iterations × ~2,000) +
    conversation_overhead(iterations × ~3,000)
```

### 2.4 Typical File Token Sizes

| File Type | Typical Size |
|-----------|--------------|
| Entity/Model class | 500-2,000 tokens |
| Service class | 2,000-8,000 tokens |
| Controller | 1,000-4,000 tokens |
| View/Template | 1,000-5,000 tokens |
| Large entity (many columns) | 5,000-10,000 tokens |
| Test file | 1,000-3,000 tokens |
| Migration | 500-1,500 tokens |

---

## Part 3: JSON Schema (Enhanced)

```json
{
  "prd_name": "Feature Name",
  "prd_path": ".kiro/specs/feature-name/requirements.md",
  "created_at": "2026-01-13T10:00:00Z",
  "model": "claude-opus-4-5",
  "context_window": 100000,
  "max_budget_per_story": 80000,
  "total_stories": 5,

  "definition_of_done": [
    "Build succeeds",
    "Tests pass with good coverage on new code",
    "Integration tests pass (if applicable)",
    "Code reviewed or self-review documented",
    "No hardcoded secrets or injection vulnerabilities",
    "All Given/When/Then acceptance criteria verified",
    "Knowledge files updated if schema/patterns changed",
    "Existing functionality unchanged (no regression)"
  ],

  "user_stories": [
    {
      "id": "US-001",
      "title": "User Story Title",

      "user_story": {
        "role": "user",
        "goal": "accomplish something",
        "benefit": "get value from it"
      },

      "priority": 1,
      "complexity": "medium",
      "epic": "E1",

      "invest_validation": {
        "independent": true,
        "negotiable": true,
        "valuable": true,
        "estimable": true,
        "small": true,
        "testable": true
      },

      "token_budget": {
        "estimated_total": 55000,
        "breakdown": {
          "knowledge_files": 15000,
          "files_to_read": 15000,
          "files_to_write": 10000,
          "tool_overhead": 10000,
          "conversation": 5000
        }
      },

      "depends_on": [],

      "files_to_read": ["path/to/file.ts"],
      "files_to_modify": ["path/to/file.ts"],
      "files_to_create": ["path/to/new-file.ts"],

      "acceptance_criteria": [
        {
          "scenario": "Happy path scenario",
          "given": "a valid precondition",
          "when": "I perform an action",
          "then": [
            "the expected result occurs",
            "the data is saved correctly"
          ]
        },
        {
          "scenario": "Error handling scenario",
          "given": "an invalid input",
          "when": "I perform the action",
          "then": ["an appropriate error is returned"]
        }
      ],

      "edge_cases": [
        {
          "scenario": "Resource not found",
          "expected": "404 Not Found with error message"
        },
        {
          "scenario": "Invalid input format",
          "expected": "400 Bad Request"
        }
      ],

      "non_functional_requirements": {
        "performance": "Response time < 500ms for 95th percentile",
        "security": "Requires authentication",
        "scalability": "Handles large data sets"
      },

      "test_strategy": {
        "unit_tests": [
          "ServiceName_MethodName_Scenario_ExpectedResult"
        ],
        "integration_tests": [
          "API endpoint returns expected data"
        ],
        "regression_tests": [
          "Existing functionality still works"
        ]
      },

      "rollback_plan": {
        "strategy": "Single commit, easy to revert",
        "database": "No migration required for this story"
      },

      "prompt": "Full prompt text for Claude...",

      "knowledge_files_to_update": ["DATABASE_SCHEMA.md"],
      "completion_promise": "US-001 COMPLETE",
      "status": "pending"
    }
  ],

  "knowledge_files": {
    "pre_load": [
      ".claude/ralph-workflow/knowledge/DATABASE_SCHEMA.md",
      ".claude/ralph-workflow/knowledge/INFRASTRUCTURE.md"
    ]
  }
}
```

---

## Part 4: Conversion Process

### Step 1: Parse PRD
Extract user stories, technical requirements, and dependencies.

### Step 2: Validate INVEST for Each Story
- [ ] Is it Independent?
- [ ] Is it Negotiable?
- [ ] Is it Valuable?
- [ ] Is it Estimable?
- [ ] Is it Small enough (< 80K tokens)?
- [ ] Is it Testable?

### Step 3: Write User Stories in Canonical Format
```
As a [role], I want [goal], so that [benefit].
```

### Step 4: Write Acceptance Criteria in Gherkin
- At least 1 happy path scenario
- At least 1 error scenario
- Include authorization scenario if endpoint is protected

### Step 5: Define Edge Cases
- What happens if resource not found?
- What happens if input invalid?
- What happens if unauthorized?
- What happens if concurrent modification?

### Step 6: Specify Non-Functional Requirements
- Performance targets
- Security requirements
- Scalability needs

### Step 7: Define Test Strategy
- Unit test naming conventions
- Integration test scope
- Regression test checklist

### Step 8: Estimate Token Budget
Calculate execution tokens and split if > 80K.

### Step 9: Generate Prompts
Include scope, files, Gherkin criteria, and knowledge update instructions.

---

## Part 5: Splitting Large Tasks

### Example: "Add New Data Processing Engine"

**Original estimate:** ~250,000 tokens (TOO BIG)

**Split into:**

| Sub-Story | Scope | Est. Tokens |
|-----------|-------|-------------|
| US-001a | Create entity + migration | ~45,000 |
| US-001b | Create interface + base class | ~50,000 |
| US-001c | Implement core logic | ~70,000 |
| US-001d | Integrate into main service | ~80,000 |
| US-001e | Add unit tests | ~60,000 |

---

## Part 6: Warning Signs

### Story Too Large
- [ ] Touches more than 8-10 files
- [ ] Requires reading a massive file multiple times
- [ ] Has more than 5 Gherkin scenarios
- [ ] Involves both database changes AND UI changes
- [ ] Requires multiple service integrations

### Story Not INVEST-Compliant
- [ ] Depends on 3+ other stories (not Independent)
- [ ] Over-specified implementation details (not Negotiable)
- [ ] Pure technical refactor with no user value (not Valuable)
- [ ] Vague scope that can't be estimated (not Estimable)
- [ ] Would take multiple sprints (not Small)
- [ ] No clear pass/fail criteria (not Testable)

**Solution:** Refactor the story.

---

## Output Location
```
.claude/ralph-workflow/stories/[feature-name].json
```

---

## References

- [INVEST Criteria](https://medium.com/tri-petch-digital/writing-effective-user-stories-from-invest-to-gherkin-95f4246a7910)
- [Given/When/Then Best Practices](https://www.parallelhq.com/blog/given-when-then-acceptance-criteria)
- [Acceptance Criteria Formats](https://www.altexsoft.com/blog/acceptance-criteria-purposes-formats-and-best-practices/)
- [Definition of Done](https://www.atlassian.com/agile/project-management/definition-of-done)
- [BDD with Gherkin](https://testquality.com/gherkin-language-user-stories-and-scenarios/)
