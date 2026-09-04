---
name: reverse-engineer-spec
description: Reverse-engineer a living functional specification (Layer 2) from a codebase — scan the code in parallel by domain area, extract numbered testable behavior rules with evidence, and produce draft docs/spec/ markdown files ready for PM review. Use this whenever the user wants to document what a product actually does today from its code, bootstrap a living spec, audit current behavior, "reverse-engineer the spec", "document current behavior", "what does this system actually do", "create functional documentation from the code", or kick off the documentation process on a repo that has no requirements docs. Also use it when a PM or team complains that behavior documentation is missing or stale and the only source of truth is the code.
---

# Reverse-Engineer a Living Functional Spec

Produce a draft **living functional spec** ("Layer 2"): per-area markdown files describing the CURRENT behavior of a product as numbered, testable rules — extracted from the code itself. The output is a draft for a PM to review (confirm/correct), which is dramatically faster than writing a spec from scratch.

Two principles drive everything:

1. **Describe what the code does, not what it should do.** Suspected bugs are documented too — flagged, not silently "fixed" in the description. A spec that mixes reality with wishes is useless for QA and support.
2. **Rules, not narrative.** Every behavior is one testable statement ("When X, the system does Z") with a stable ID (e.g. `COMP-14`) so tickets, tests, and support answers can cite it.

## Process

### Step 1 — Orient (10 minutes, main context)

Read the repo's `CLAUDE.md` / `README` / architecture docs if present. Identify:

- The stack and where behavior lives (backend services, frontend validation, triggers, scheduled jobs)
- The core entities (the domain nouns: users, orders, companies…)
- Cross-cutting mechanisms (request/command pattern, auth/permissions, notifications, integrations)

If the product spans multiple repos (backend + frontend), include both — frontend code encodes real behavior (validation rules, permission gating, status displays) that backend-only scans miss.

### Step 2 — Partition into area clusters

Split the product into 4–6 clusters for parallel scanning. A reliable default partition:

1. One cluster per 1–3 related **entities** (their full lifecycle: create, edit, validate/approve, archive, delete)
2. **Scheduled/background jobs + integrations** (crons, queues, external systems)
3. **Auth, users, roles, permissions** (+ anything account-shaped)
4. **Notifications + emails** (often scattered; deserves its own sweep)
5. **Frontend UX rules** (routing, form validation, status displays, gated buttons)

Don't over-split: each agent needs enough scope to see how pieces connect (e.g. the same agent should see both an entity's create service and its validation trigger).

### Step 3 — Fan out parallel exploration agents

Spawn one read-only exploration agent per cluster, **all in a single message** so they run concurrently. Build each prompt from `references/area-agent-prompt.md` — read it first; the quality of the final spec is determined almost entirely by how demanding these prompts are.

The non-negotiables for every agent prompt:

- Report **numbered, testable rules of CURRENT behavior**, each with `file:line` evidence
- Cover: preconditions/validations, state transitions, side effects (notifications, emails, cascades), error cases with exact messages/codes, thresholds and time windows with exact values
- Include entity field structures (concept-table material)
- **Flag anything that looks like a bug, dead code, or inconsistency** — these are often the most valuable findings
- "Be exhaustive — this report is the sole source for the spec section"

### Step 4 — Synthesize into spec files

While agents run, decide the file layout. Then write one file per area into `docs/spec/` in the main repo, using `assets/template-functional-spec.md` as the structure. Follow these rules:

- **Rule IDs** with a short area prefix: `COMP-1`, `AUTH-12`, `ENT-E1` for error rules. IDs are permanent reference points.
- **Concept table** first: entities, fields, states — so rules are unambiguous.
- **⚠️ Confirm intent** marker on any rule where the code's behavior is plausibly unintended. This turns PM review into a targeted pass instead of a full audit.
- **"Known gaps and quirks"** section at the bottom of each file for suspected bugs, dead code, threshold inconsistencies, and security concerns. Never present a suspected bug as intended behavior.
- Mark every file **DRAFT — reverse-engineered from code, pending PM review** at the top. The spec only becomes the source of truth after that review.
- Keep the agents' `file:line` evidence out of the final spec (it goes stale), but keep exact values in: day thresholds, error codes, email template names, schedule times.

Also write a `README.md` index: table of files, their rule prefixes, and the update rule ("any PR that changes behavior updates the affected spec file in the same PR").

A good target size: each area file readable in ~5 minutes; split areas that exceed that.

### Step 5 — Deliver two things

1. **The spec files**, committed or presented for commit in `docs/spec/` of the main repo.
2. **A triage list of suspected bugs** found during the scan, ranked by severity, presented in chat. Reverse-engineering a spec almost always surfaces real bugs (broken dedup logic, unreachable code, security gaps) — surfacing them separately is a large part of the value. Offer to create tracker issues for them.

## Writing behaviors well — behavior-first

The spec is read by PMs, QA, and support, not just engineers. The exploration agents report in code vocabulary; **translating that into product language is the synthesis step's main job.**

- Lead every rule with what the user or platform *visibly does*, in plain product language — the same style as a feature spec's acceptance criteria. "An archived company cannot be edited" — not "the edit handler throws when validationStatus is archived".
- Demote technical identifiers to an italic parenthetical at the end, and only keep the ones that earn their place: exact error codes (support matches them against user reports), email template names (traceability), thresholds/schedules (QA verifies them). *(error `company.archived`)* — not woven into the sentence.
- Purely internal mechanics that no user ever observes (unawaited writes, trigger wiring, collection names) go in "Known gaps and quirks" — or nowhere. Not in the rules.
- One rule per bullet. If a rule needs "and", check whether it's two rules. If you can't imagine the test for a rule, rewrite it.
- Exact values stay: "within **15 days**" not "soon".
- Cross-reference rules by ID across files instead of repeating them (e.g. "resets status per SYS-7").
- Notification/email behavior fits best in a matrix table: when it's sent → who receives it *(template name)*.

## Example rules (target quality)

- **COMP-14.** A regular company can only be validated if it has at least one **validated** employee *(error `noValidEmployees`)*. Sub-companies skip this check.
- **COMP-8.** An archived company cannot be edited *(error `company.archived`)*.
- **ENT-4.** ⚠️ **Bug:** the duplicate check only asks "does this job already have any entry" — a job with several employees or sites only ever gets **one** entry, never backfilled. _Needs fix decision before this becomes a rule._
- **AUTH-4.** Archiving a user blocks them from the app, but their login account itself stays enabled. Restore always sets them back to active, with no checks.
