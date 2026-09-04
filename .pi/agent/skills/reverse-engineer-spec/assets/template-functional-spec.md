# Functional Spec: [Product area]

> Layer 2 — living document. Describes **current** behavior, always. Lives in `docs/spec/` in the product repo.
> Rule: any PR that changes behavior in this area updates this file in the same PR. Enforced in code review, like tests.
> One file per product area (e.g. `authentication.md`, `billing.md`, `notifications.md`). Split when a file gets unwieldy.

| | |
|---|---|
| **Area owner (PM)** | |
| **Last verified** | [date someone confirmed this matches reality] |

## Overview

3–5 sentences: what this area does and who uses it. Just enough orientation to read the rules below — no marketing language, no history.

## Concepts

Terms and entities used in this area, so rules are unambiguous. Describe them in product language, not database language.

| Term | Meaning |
|---|---|
| [Term] | [Precise definition, including states/lifecycle if relevant] |

## Behaviors

The core of the document. Rules, not narrative. Each rule is one testable statement of current behavior, written **behavior-first**:

- Lead with what the user or platform visibly does, in plain product language — the same style as a feature spec's acceptance criteria.
- Put technical identifiers in an italic parenthetical at the end, only when they earn their place: exact error codes (support matches them against user reports), email template names (traceability), thresholds and schedules (QA verifies them).
- Purely internal mechanics that no user ever observes belong in "Known gaps and quirks" or nowhere — not in the rules.

Group by capability, number for referencing from tickets/tests/support.

### [Capability 1, e.g. "Login"]

- **AUTH-1.** [What happens, in product language] *(error `x`, template `y`, N-day window)*.
- **AUTH-2.** Given [context], when [action], then [outcome].

### [Capability 2]

- **XXX-1.** ...

### Errors and limits

- **XXX-E1.** When [invalid input / failure / limit reached], the user [sees Z] *(error `code`)*.

## Permissions

Who can do what in this area (skip if not applicable).

| Action | Role(s) allowed | Notes |
|---|---|---|
| | | |

## Integrations and side effects

What this area triggers or depends on elsewhere: events emitted, emails sent, other areas affected, external services called.

- ...

## Known gaps and quirks

Behavior that exists but is acknowledged as wrong/awkward — documented so nobody mistakes it for intended design, with a tracker link if a fix is planned. Internal implementation oddities (unawaited writes, dead code, mismatched constants) also live here.

- ...

---

*How to update: edit the affected rules in the same PR that changes the behavior. New feature shipped? Merge its Feature Spec behaviors here (keep the numbering scheme) and archive the Feature Spec. Don't append changelogs here — git history is the changelog.*
