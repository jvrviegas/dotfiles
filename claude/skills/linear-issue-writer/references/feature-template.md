# Feature / Task issue template

Use for new behavior, changes to existing behavior, chores, migrations, and spikes. Sections marked *(optional)* are omitted entirely when they don't apply — never leave an empty heading.

## Skeleton

```markdown
# <Imperative title stating the task — include the key rule if it fits>

## Context

<2–4 sentences: why this exists now, who needs it, what happens if it's not done.
Link every source: spec file path + section, client decision (dated, with decider),
parent/related issues by real identifier.>

## What to Build

<The concrete deliverable, in plain prose. What exists after this issue is done
that doesn't exist today? For a spike: the question to answer and the artifact
that answers it (document, PoC, decision). Numbered sub-points are fine when the
task has distinct components, but if a sub-point has its own outcome, it should
be its own issue.>

## Business Rules

<Every rule an implementer must honor, stated exactly — and stated as OBSERVABLE
BEHAVIOR, not as a storage or code mechanism:
- Validations with their exact logic ("NIF check digit via modulo-11")
- Permissions as a role → action matrix (use a table)
- Formulas spelled out ("retention_start_at = MAX(event.closed_at, questionnaire.closed_at)")
- State machines as a table (state → allowed transitions → side effects)
- Edge-case decisions, each with its source ("decided 2026-07-27 by <name>")
- Right: "at most one active attendance record per employee per date; deleting
  a record frees the date for re-registration."
  Wrong: "partial unique index (employeeUserId, date) WHERE deleted_at IS NULL."
  The index is a mechanism — if enforcing it in the database is a hard requirement,
  say so as a constraint under AI Handoff.>

## Acceptance Criteria

- [ ] <Each independently verifiable — a tester could mark it true or false>
- [ ] <Cover the happy path(s)>
- [ ] <Cover negative/refusal cases: what must be rejected, and with what message/status>
- [ ] <Cover empty/loading/error states for UI work>
- [ ] <Assert behavior, not test existence or implementation artifacts — "expired
      tokens are rejected with 401", not "tests cover token expiry"; "re-registering
      after deletion creates a new active record", not "entity + migration created">

## Out of Scope *(optional but recommended)*

- <Exclusion> — handled in <linked issue>
- <Exclusion> — deliberately deferred because <reason>

## Dependencies

Blocked by: <linked issues, or "None — can start immediately">
Blocks: <linked issues, if known>

## AI Handoff

<Everything an AI agent needs to produce an implementation plan without asking
questions — boundaries, contracts, and constraints, NOT solutions. This section
feeds the implementation plan; it must not be one. Never prescribe libraries,
ORM/SQL syntax, algorithms, or code snippets. Include only the subsections that apply.>

**Repo / module:** <repository and area of the codebase>

**Files to touch:**
- `path/to/file.ts` — modified: <what changes>
- `path/to/new-file.ts` — new: <what it contains>
<If the codebase is unknown, name the layer ("the companies service, wherever
company updates are handled") and mark "exact path to be located by implementer".>

**Data model:** <what data is captured — fields with name, type, default, and
*semantics* (uniqueness, nullability, what NULL means). Storage mechanics — index
syntax, ORM annotations — stay out; enforcement requirements become constraints.>

**API contract:** <method + path, request/response shape, and an error table:>
| Condition | Status | Response |
|---|---|---|
| <condition> | <code> | <body/message> |

**Test plan:** <what to test and at which level (unit/integration/e2e), including
the negative cases from the AC>

**Constraints:** <the technical decisions that ARE requirements, phrased as limits:
"uniqueness enforced at the database level, not only application code"; "no new
dependencies for date/timezone handling"; "reuse the existing holiday calendar
(calendars module) — same lookup pattern as chargeable-days"; migrations and their
rollback, feature flags, performance budgets, "⚠️ Human-in-the-loop:" warnings for
anything touching production data. When a tech review fixed a decision, record it
here with date/owner — the chosen mechanism goes in the PR, not the issue.>

## Open Questions *(optional)*

- ⚠️ <Question> — owner: @<name>. Interim assumption: <the safe reading this issue
  was written against>.

## References *(optional)*

<Spec: `docs/...` §X · Design: <Figma/mockup link — flag to the user if UI work has
no design reference> · Related: CP-xxx, PRO-xxx>
```

## Section guidance

**Title.** Imperative verb first. Encode the defining rule when short: "Enforce the five publish preconditions" is better than "Publish validation". Under ~70 characters so it scans in list views.

**Context.** The *why*, not the *what*. A reader who knows nothing about the planning meeting should understand the motivation and be able to follow every link. This is where user context lives ("municipal managers need this to compare clusters") — as fact, not as a user story.

**What to Build vs Business Rules.** What to Build says what the thing *is*; Business Rules says what the thing must *obey*. Keeping rules in their own section makes them findable — the audit found projects where ~90% of issues contained rules but none under a findable heading.

**Acceptance Criteria.** The single most valuable section. Aim for 5–15 boxes on a typical feature. Every box must be falsifiable. Always include at least one refusal case — the audit's best issues specify what the system must *not* do ("re-running the seed changes nothing"; "soft delete is refused when the event has one or more responses").

**AI Handoff.** Boundaries, contracts, and constraints — not solutions. The issue is the *input* to an implementation plan; if the description already dictates the ORM feature, the SQL syntax, the date library, or the algorithm, it has done the AI's job badly and gone stale in advance. What earns its place here: error cases as a table including fail-closed behavior ("DB unreachable on cache refresh → throw, fails closed"), field-level data semantics ("at most one active row per equipment; NULL tenant means global"), file paths as integration pointers with new/modified markers, reuse pointers ("reuse the existing holiday calendar in the calendars module"), and hard requirements phrased as constraints ("uniqueness enforced at the database level"). What doesn't: "written as raw SQL in the TypeORM migration", "computed with native Intl APIs", "jsonb dates[] with category enum" — all of that is the implementer's (or AI's) call, recorded in the PR. This is why an AI agent can start planning immediately *and* still owns the plan.

## Gold example (abridged)

```markdown
# Feature flags: per-tenant storage and resolution with 60s cache

## Context

Rollouts currently require a deploy to toggle behavior. We need runtime flags,
per tenant, before the Notion editor beta (PRO-1573) can ship to a subset of
clients. Spec: `docs/feature-specs/feature-flags.md` §B1–B4.

## What to Build

A `feature_flags` table, a resolution service with in-memory caching, and a
`GET /flags` endpoint returning the resolved flags for the caller's tenant.

## Business Rules

- Resolution order: tenant override → global default → code default (in that order)
- Cache TTL: 60 seconds; flags may be stale up to TTL, never longer
- Unknown flag keys resolve to the code default and log a warning — they never throw
- Only `superadmin` may write flags; all writes are audit-logged

## Acceptance Criteria

- [ ] A tenant override wins over a global default for that tenant only
- [ ] Two resolutions inside the TTL issue one DB query; a third after TTL expiry issues a second
- [ ] A request for an unknown flag key returns the code default and logs a warning
- [ ] A non-superadmin write attempt is rejected with 403 and no audit entry is created
- [ ] DB unreachable during cache refresh → the service throws (fails closed), it does not serve stale flags past TTL

## Out of Scope

- Flag management UI — handled in PRO-1551
- Percentage rollouts — deliberately deferred until a client needs them

## Dependencies

Blocked by: None — can start immediately
Blocks: PRO-1573

## AI Handoff

**Repo / module:** `internal-platform`, backend

**Files to touch:**
- `backend/src/flags/flags.service.ts` — new: resolution + cache
- `backend/src/flags/flags.controller.ts` — new: GET /flags
- `backend/src/migrations/` — new migration (see data model)

**Data model:**
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| tenant_id | uuid, nullable | FK tenants; NULL = global default |
| key | text | unique together with tenant_id |
| value | jsonb | not null |

**API contract:** `GET /flags` → `200 { [key]: value }` for caller's tenant
| Condition | Status | Response |
|---|---|---|
| Unauthenticated | 401 | standard error body |
| Write by non-superadmin | 403 | `FORBIDDEN` |

**Test plan:** unit — resolution order, TTL behavior, unknown keys; integration —
403 path, audit entry on write.

**Constraints:** migration must have a working `down()`; no feature flag for the
flag system itself.
```
