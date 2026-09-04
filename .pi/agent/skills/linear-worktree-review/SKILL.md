---
name: linear-worktree-review
description: Reviews an implementation in a local git worktree against a Linear issue's requirements, runs relevant validation, and saves a structured verdict under docs/reviews/. Supports follow-up re-reviews after fixes. Use when asked to review or re-review a Linear issue implementation in a worktree, validate local work against acceptance criteria, or create a requirements review file.
---

# Linear Worktree Review

Review only: do not edit implementation code, push commits, post comments, or change issue/PR state.

## Inputs

- Linear issue identifier, e.g. `DEV2-985`
- Worktree path or enough context to discover it
- Optional `re-review` request

Load the `linear` skill before reading Linear. Honor repository Linear defaults from `AGENTS.md`.

## Initial review

1. Fetch the Linear issue and comments. Extract acceptance criteria, business rules, constraints, dependencies, test plan, and quality gate.
2. Locate the worktree. Confirm branch, HEAD, cleanliness, base commit, changed files, linked PR, and issue state. A missing PR or non-review state is metadata, not a reason to stop when local review was requested.
3. Inspect the complete implementation diff and relevant neighboring code. Verify behavior from code; never trust checked issue boxes or test names alone.
4. Run focused tests, then the full feasible quality gate. Record exact commands, pass/fail counts, warnings, and checks not performed.
5. Classify findings:
   - **Blocker:** unmet requirement, correctness/reliability/security issue, regression, or introduced quality-gate failure.
   - **Optional:** non-blocking maintainability or hardening improvement.
6. Evaluate every acceptance criterion as ✅ Met, ⚠️ Probable, or ❌ Not met, with `path:line` evidence.
7. Choose a binary verdict:
   - ✅ **Approved:** no open blockers or ❌ criteria.
   - ❌ **Changes Requested:** any open blocker or ❌ criterion.
8. Write `docs/reviews/<ISSUE-ID>-implementation-review.md` using [REFERENCE.md](REFERENCE.md). Create the directory when absent.

## Re-review

Trigger when the user says `re-review <ISSUE-ID>`, asks to validate fixes, or selects re-review after the initial report.

1. Read the existing review file first and treat its blockers/optional items as the checklist.
2. Fetch the current issue, inspect commits and diff since the previously reviewed SHA, and re-check all acceptance criteria for regressions.
3. Re-run focused tests and relevant quality gates; do not rely on prior results.
4. Mark each prior item ✅ Resolved, ⚠️ Partially resolved, ❌ Still open, or ➖ No longer applicable. Add newly discovered findings separately.
5. Update the same review file: keep the original review, insert a current verdict near the top, and append a dated `Re-review` section with current SHA and evidence.
6. Apply the same binary verdict rules. Never approve while a blocker is partial/open.

## Required response

State the verdict and review-file path. Summarize blockers briefly. Do not post anywhere automatically.

End every initial review and every Changes Requested re-review with:

> **Next step:** After the fixes are committed, ask me to `re-review <ISSUE-ID>` and I will validate the previous blockers, rerun the checks, and update this review file.

After an Approved re-review, offer another re-review only if more commits are added.
