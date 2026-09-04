# Bug issue template

Use for observed wrong behavior. The audit found bugs are where issue quality collapses (<10% of QA bugs had acceptance criteria; client-intake bugs were screenshot-only, sometimes Portuguese-only, with no reproduction steps). This template is deliberately lightweight — a bug report should take minutes, not require a spec — but nothing on this list is optional without a stated reason.

Two situations:

- **Reporting** (you know the symptom): fill everything down to Evidence; write the fix-oriented sections only as far as you know them. Frame the problem; let the assignee propose the fix (Linear method: when others file issues, frame them as problems).
- **Fixing** (root cause known): fill everything, including Root Cause with file:line and the AC for the fix.

## Skeleton

```markdown
# <Imperative title stating the fix — or the precise defect if the fix is unknown>

## Context

<1–3 sentences: where this was found (client report, QA pass, monitoring), who
reported it, when, and the impact/severity. Link the original report (ITSM ticket,
Slack thread) by ID. If the report was in Portuguese, quote it verbatim and
translate:>

> Original (PT): "<verbatim quote>"
> EN: "<translation>"

## Environment

<App/service + version or commit, environment (prod/staging/local), tenant/account
used, browser or device if relevant, date/time observed.>

## Steps to Reproduce

1. <Numbered, from a clean state, including the account/role used>
2. <…>

## Expected

<What should happen — cite the Business Rule or spec section that says so, if one exists.>

## Actual

<What happens instead. Transcribe the exact error text, status code, or wrong value —
never rely on a screenshot alone; attached image URLs expire and AI agents cannot
read them. Keep screenshots as supplementary evidence.>

## Root Cause *(when known)*

<File:line and the mechanism — e.g. "`Object.assign(company, dto)` in
`companies.service.ts:440` overwrites entity fields with `undefined`".>

## Acceptance Criteria

- [ ] <The observable behavior after the fix — falsifiable>
- [ ] <The reproduction steps above no longer produce the defect>
- [ ] <A regression guard: the adjacent behavior that must NOT change>

## Dependencies

Blocked by: <linked issues, or "None — can start immediately">

## AI Handoff *(when the fix is scoped)*

**Files to touch:** <paths with modified markers, if known>
**Test plan:** <the regression test that would have caught this>
**Constraints:** <"⚠️ Human-in-the-loop:" if the fix touches production data; data
backfill/migration notes>
```

## Section guidance

**Title.** Name the task or the precise defect, not the symptom trail. "Fix partial company update nullifying unset fields" beats "[Companies] When All cluster's tab is selected, company deletion does not work, yet the Delete option…". If the issue is a report and the fix is unknown, a precise defect statement is fine: "Company PATCH erases fields omitted from the payload".

**Environment.** The most commonly missing section in the audit — and the first thing an investigating engineer needs. Thirty seconds to write, hours saved.

**Actual + Evidence.** Transcription is the rule that matters most. Signed screenshot URLs (uploads.linear.app) expire; an issue whose entire body is "Imagens em anexo." becomes permanently unreadable. Copy the error message, the wrong number, the offending request/response into the text. A curl transcript (as in CP-815) is the gold standard for API bugs.

**Acceptance Criteria.** Yes, bugs get AC too — this is the single biggest gap the audit found. Minimum three boxes: the corrected behavior, the reproduction now failing to reproduce, and one regression guard.

## Gold example (abridged)

```markdown
# Fix partial company update nullifying fields omitted from the payload

## Context

Found during cycle-9 client UAT; reported by SPZ admin via ITSM PR-000101 on
2026-07-30. Editing only a company's name erases its CAE and address. Severity:
high — data loss in production.

> Original (PT): "Ao editar o nome da empresa, a morada desaparece."
> EN: "When editing the company name, the address disappears."

## Environment

dash2zero-api v1.14.2, production, tenant SPZ, observed 2026-07-30 ~15:20 WEST.

## Steps to Reproduce

1. As a client admin, open any company with a filled address
2. Edit only the name field and save
3. Reload the company detail page

## Expected

Fields omitted from the PATCH payload keep their stored values (partial-update
semantics per `docs/feature-specs/02-companies.md` §4.2).

## Actual

Address and CAE are null after save. API log: `PATCH /companies/931` body
`{"name":"Novo Nome"}` → subsequent `GET` returns `"address": null, "cae": null`.

## Root Cause

`Object.assign(company, dto)` in `companies.service.ts:440` copies `undefined`
DTO properties over stored entity fields.

## Acceptance Criteria

- [ ] PATCH with a partial payload updates only the provided fields
- [ ] The steps above leave address and CAE unchanged
- [ ] Explicitly sending `"address": null` still clears the field (intentional nulls keep working)
- [ ] A regression test covers partial update with each optional field omitted

## Dependencies

Blocked by: None — can start immediately

## AI Handoff

**Files to touch:** `companies.service.ts` — modified: replace blind Object.assign
with defined-keys merge; `companies.service.spec.ts` — modified: add regression cases.
**Test plan:** unit — partial payloads, explicit nulls; integration — PATCH → GET round-trip.
**Constraints:** ⚠️ Human-in-the-loop: check whether production rows already lost
data and need a restore from audit log before closing.
```
