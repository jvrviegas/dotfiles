# Phase 2 — Manual verification guide

Goal: a document the reviewer can follow by hand to reproduce every finding from Phase 1 — without you. Write it from what you actually verified; every expected result in the guide must be one you observed.

## Structure

Two parts plus a checklist. Use concrete dates/values that will still work when the user runs it days later (say "replace with a date a few days ahead" where relevant).

### Part A — Codebase review

A file-by-file checklist mapped to the rubric criteria. For each item: a table or list of **Open** (exact path) → **Look for** (the specific mechanism, named — e.g. "the `EXCLUDE USING gist` constraint; note the half-open range and the `WHERE` clause"). Cover, in rubric-weight order:

1. The core correctness mechanism (concurrency/caching/algorithm) — where it lives, what a *wrong* implementation would look like instead (e.g. "no pre-check before insert — a read-then-write here would be the race").
2. Business rules — the pure-logic layer, boundary semantics.
3. Data model — types, constraints, indexes, soft-delete/history handling.
4. Auth/roles — where enforcement lives server-side; hygiene (hashing, enumeration).
5. Tests — which test proves which rule; whether they assert datastore state.
6. Strictness/organization — the greps to run (`: any`, config flags).
7. README cross-check — verify claims verbatim against the files they cite.
8. Commit history — the exact `git log` command and what pattern to expect.

### Part B — Running application

Step-by-step with copy-paste commands and **expected outputs** (status codes, JSON fragments, UI states):

1. **Start**: the one-command boot, how to confirm healthy, URLs + seeded credentials.
2. **UI walkthrough per role** — numbered steps covering each functional requirement, including the edge cases (boundary slots, disabled options, error toasts) and a two-window race check if concurrency applies.
3. **API checks with curl** — token acquisition first (as copy-paste shell), then one numbered check per rule with the exact command and expected `[code]`. Include: validation rejections, role enforcement, the true concurrency loop (`&` + `wait`), boundary cases, and any deliberate design choices worth confirming (e.g. 404-not-403).
4. **Candidate's own test suite** — their documented command + expected counts.
5. **Datastore-level spot check** (optional but convincing) — e.g. a raw SQL insert that the constraint must reject.
6. **Cleanup** — teardown commands.

### Expected-results checklist

End with a `- [ ]` checklist, one line per verifiable claim, so the reviewer can tick through it.

**Save as** `manual-verification-guide-<challenge>-<candidate-slug>.md` next to the evaluation report (outside the candidate repo).
