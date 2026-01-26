# Implementation Blueprint Template

This template defines the structure for Implementation Blueprints produced by the `/design-solution` skill.

---

## Blueprint Document Structure

```markdown
# Implementation Blueprint: [Feature Name]

## Metadata
- **PRD:** `.kiro/specs/[feature]/requirements.md`
- **Research:** `.kiro/specs/[feature]/research/`
- **Created:** [ISO-8601 timestamp]
- **Status:** Ready for story generation

---

## Research Synthesis Summary

### Key Findings
- [Most critical discovery from research - 1]
- [Most critical discovery from research - 2]
- [Most critical discovery from research - 3]

### Constraints Carried Forward
- [Critical constraint that must be enforced in stories]
- [Another critical constraint]

### Assumptions Made
| Assumption | Risk Level | Impact if Wrong |
|------------|------------|-----------------|
| [Assumption 1] | Low/Med/High | [What happens] |
| [Assumption 2] | Low/Med/High | [What happens] |

---

## Solution Architecture

### Data Layer

**Approach:**
[2-3 sentences describing the database/model strategy and rationale]

**Constraints:**
- [Data-layer-specific constraint from research]
- [Another constraint]

**Suggested Files:**
| Action | File Path | Purpose |
|--------|-----------|---------|
| Create | `path/to/NewModel.ts` | New entity definition |
| Create | `path/to/migration.ts` | Schema migration |
| Modify | `path/to/index.ts` | Export new model |

**Token Budget Estimate:** ~[X]K tokens

---

### Service Layer

**Approach:**
[2-3 sentences describing the business logic organization and rationale]

**Constraints:**
- [Service-layer-specific constraint]

**Suggested Files:**
| Action | File Path | Purpose |
|--------|-----------|---------|
| Create | `path/to/FeatureService.ts` | Core business logic |
| Modify | `path/to/index.ts` | Export new service |

**Token Budget Estimate:** ~[X]K tokens

---

### API Layer

**Approach:**
[2-3 sentences describing the endpoint design, versioning, contracts]

**Constraints:**
- [API-layer-specific constraint]

**Suggested Files:**
| Action | File Path | Purpose |
|--------|-----------|---------|
| Create | `path/to/routes/feature.ts` | Route definitions |
| Create | `path/to/dto/FeatureDto.ts` | Request/response DTOs |
| Modify | `path/to/routes/index.ts` | Register routes |

**Token Budget Estimate:** ~[X]K tokens

---

### UI Layer

**Approach:**
[2-3 sentences describing the component structure, screen flow, UX approach]

**Constraints:**
- [UI-layer-specific constraint from UI/UX research]

**Suggested Files:**
| Action | File Path | Purpose |
|--------|-----------|---------|
| Create | `path/to/components/Feature/List.tsx` | List view |
| Create | `path/to/components/Feature/Form.tsx` | Create/edit form |
| Modify | `path/to/routes.tsx` | Add navigation |

**UI/UX Reference:** See `research/ui-ux/screenshots/`

**Token Budget Estimate:** ~[X]K tokens

---

## Cross-Cutting Concerns

### Authentication & Authorization
[How this feature handles auth — specific roles, permissions, middleware to use]

### Error Handling
[Error strategy — what errors are possible, how they propagate, how they surface to users]

### Logging & Observability
[What gets logged, metrics to emit, tracing spans to create]

### Caching (if applicable)
[Cache strategy, invalidation approach, TTLs]

---

## Integration Points

| External System | Type | Direction | Notes |
|-----------------|------|-----------|-------|
| [System name] | REST API / Event / DB | In/Out | [Connection details, auth] |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Technical risk] | Low/Med/High | Low/Med/High | [Strategy to mitigate] |
| [Integration risk] | Low/Med/High | Low/Med/High | [Strategy to mitigate] |

---

## Constraints for Story Generation

> **IMPORTANT:** These rules MUST be enforced by `/solution-to-stories` when generating user stories.

1. [Constraint 1 - e.g., "All database changes must use TypeORM migrations"]
2. [Constraint 2 - e.g., "API endpoints must follow `/api/v1/[resource]` convention"]
3. [Constraint 3 - e.g., "All endpoints require `authMiddleware`"]
4. [Constraint 4 - e.g., "UI components must use `@/components/ui` design system"]
5. [Constraint 5 - e.g., "Forms must use `FormBuilder` pattern"]
6. [Constraint 6 - e.g., "Error responses must follow RFC 7807"]

---

## Story Sequencing Recommendation

Suggested order for story generation to minimize dependencies:

1. **Data Layer First** — Models and migrations (no dependencies)
2. **Service Layer Second** — Business logic (depends on models)
3. **API Layer Third** — Endpoints (depends on services)
4. **UI Layer Last** — Components (depends on API)

### Parallel Execution Opportunities
- Stories within same layer can often run in parallel
- Data layer stories: [parallel/sequential]
- Service layer stories: [parallel/sequential]
- API layer stories: [parallel/sequential]
- UI layer stories: [parallel/sequential]

---

## Appendix: File Tree Summary

```
Files to CREATE:
├── [full path 1]
├── [full path 2]
└── [full path N]

Files to MODIFY:
├── [full path 1]
└── [full path N]
```

---

## Appendix: Token Budget Summary

| Layer | Estimated Tokens | Stories |
|-------|-----------------|---------|
| Data | ~[X]K | [N] |
| Service | ~[X]K | [N] |
| API | ~[X]K | [N] |
| UI | ~[X]K | [N] |
| **Total** | **~[X]K** | **[N]** |

Buffer remaining: ~[X]K tokens per story (target <80K each)
```

---

## Blueprint Validation Checklist

Before a blueprint is considered complete, verify:

- [ ] All 4 layer sections present (Data, Service, API, UI)
- [ ] Each layer has Approach, Constraints, and Suggested Files
- [ ] Cross-cutting concerns addressed
- [ ] "Constraints for Story Generation" section complete
- [ ] Story sequencing recommendation provided
- [ ] Token budget estimates reasonable (<80K per story)
- [ ] Risk assessment includes mitigation strategies
- [ ] Research synthesis summary accurately reflects findings
