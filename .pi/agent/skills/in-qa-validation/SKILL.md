---
name: in-qa-validation
description: QA-validate a Linear issue in 'Testing' by exercising the deliverable at runtime and asserting every acceptance criterion with independently verified evidence. Use when the user says 'QA PRO-XXX', 'test PRO-XXX', 'in-qa check', 'validate the testing ticket', or an issue has just moved to Testing and needs QA sign-off. Read-only on Linear/GitHub — produces a pass/fail AC report plus a Linear comment draft awaiting user approval.
---

# In-QA Validation

You take a single Linear issue in **Testing** state and assert the implementation against its acceptance criteria — primarily by **running the deliverable and observing behaviour**, not by reading code. Code review already happened (In Review); QA's job is to prove the thing works, catch what static review missed, and check side effects. This is read-only: never push commits, change ticket status, approve PRs, or post comments without explicit user approval.

## Inputs

A single Linear issue identifier (e.g. `PRO-1377`). If the prefix doesn't resolve, ask the user to confirm the team key — never guess.

## Linear scoping

Same resolution order as `in-review-validation`: `AGENTS.md` > `CLAUDE.md` > `MEMORY.md` in the repo, then the issue prefix (confirm with user), then `list_teams`/`list_projects` as last resort. If team/project can't be determined confidently, stop and ask. Send real newlines to Linear tools, never literal `\n`.

## Phase 1: Pull issue + history + code ref

Run in parallel:

1. `get_issue` with `includeRelations: true` — acceptance criteria, state, assignee, attachments (PR URL), blocking relations.
2. `list_comments` with `orderBy: createdAt` — full thread: the review comment(s), any prior QA findings, and fix notifications.
3. `gh pr view <N> --json state,mergeable,headRefName,headRefOid,mergeCommit,files,commits` for the linked PR.
4. `git fetch origin`.

Warn (but continue if the user insists) when the issue isn't in **Testing**. Bail out clearly if no PR/branch can be resolved.

**Which code to test:** if the PR is merged, QA the merge target branch at the merge commit (that's what ships); if still open, QA the PR head. Use a detached worktree (`.worktrees/<ISSUE-ID>-qa`) exactly as in `in-review-validation`, and remove it when done.

## Phase 2: Build the QA checklist

From the issue description, extract every acceptance criterion. From the comment thread, extract:

- **Previously flagged items** — blockers/optionals from review and any earlier QA round: re-verify each at runtime, don't assume fixed.
- **Reviewer's verification claims** — what the reviewer says they already checked; QA re-verifies the runtime-observable ones independently rather than inheriting the ✅.

## Phase 3: Exercise the deliverable (the core of QA)

Pick the validation mode by deliverable type — combine when a ticket spans several:

- **App/UI feature** — start the app (dev server + Firebase emulators or whatever the repo's run setup is), seed if needed, then drive the feature **in Chrome** using the `mcp__claude-in-chrome__*` tools (load them via one ToolSearch call; `tabs_context_mcp` first, then create a new tab). Log in as the relevant user and exercise the flow end-to-end. Verify rendered values against the underlying data with exact numbers (counts, KPI values), not "looks right". **Capture a screenshot per acceptance criterion** at the moment it's demonstrated (plus one per new finding showing the defect); save them to the scratchpad with descriptive names (`<ISSUE-ID>-ac1-dashboard-counts.png`). Also check the browser console via `read_console_messages` for errors introduced by the change.
- **Script (seed/migration/CLI)** — run it on a clean state. Then run it **again**: idempotency and re-run cleanup scope are mandatory checks. If it deletes/overwrites anything, plant **sentinel data** that must survive (e.g. a record belonging to another tenant/owner) and prove it does.
- **Notebook/analysis** — re-execute end-to-end in a fresh venv from the repo's requirements (exit 0 required). Diff regenerated outputs against committed ones. Independently recompute 1–2 headline numbers from the raw data with your own code — committed outputs prove nothing.
- **SQL deliverable** — run every query against the real DB; sanity-check result shapes and spot-verify one aggregate independently.

## Phase 4: Side-effect and environment sweep

QA owns what static review misses. Always check:

- **Destructive operations on shared state** — any delete/update whose filter could match more than the feature's own data (shared dev DB, default tenant, other trainees' work). Trace the actual filter values against how the environment is really populated.
- **Cross-cutting isolation** — tenant/user scoping holds end-to-end (rules, queries, UI), verified with sentinel data where possible.
- **Repo hygiene** — stray files, accidental commits from other tickets, PR scope wider than the ticket.
- **Console/runtime noise** — errors or warnings introduced by the change.

## Phase 5: Verdicts

Per acceptance criterion: ✅ **Verified** (observed at runtime, evidence with exact numbers) · ⚠️ **Probable** (static evidence only — say what runtime step is missing and why it couldn't run) · ❌ **Failed**. Never mark ✅ from the description's ticked checkbox or the reviewer's earlier claim alone.

Classify anything new found as **Blocker** (breaks an AC, loses data, or affects shared environments) or **Non-blocking note**.

## Phase 6: Output report

```
# <ISSUE-ID> — QA Validation (Testing)

**PR:** #<N> (<sha short>, <merged into X | open>) · **Validated:** <what was actually run — e.g. "emulators + app UI as demo admin", "notebook re-exec in fresh venv">

## Acceptance Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|

## Previously flagged items (re-verified)

| # | Item | Status | Evidence |
|---|------|--------|----------|

## New findings

| # | Finding | Severity | Evidence |
|---|---------|----------|----------|

## Verdict

- **ACs verified:** <n/total> · **Blockers:** <count> · **Non-blocking notes:** <count>
- **Recommendation:** <QA passed — ready for Done · QA failed — bounce to In Progress · passed with manual caveat>

## Screenshots (frontend tickets)

<one line per screenshot: file path + which AC/finding it evidences>

## Manual checks the validator could not perform

## Linear issue comment draft

> Awaiting user approval before posting this to Linear.
```

The comment draft follows the project's QA voice (see history on PRO-1377/PRO-1383):

- **Pass:** lead with what was validated at runtime and how; AC list with ✅ + exact-number evidence; "Notes (non-blocking)" section; close with the recommendation ("ready for Done" — status move stays the user's call).
- **Frontend tickets:** offer to attach the screenshots to the Linear comment on approval (`prepare_attachment_upload` → `create_attachment_from_upload`, or embed in the comment body); never upload before the user approves the comment.
- **Fail:** title `## ⚠️ QA finding (Testing) — <one-line summary>`; state what passes first; then per finding: the problem, the evidence (code/output snippet), and a **proposed fix** (concrete, with code when short); verdict suggesting a bounce to **In Progress** and re-QA. Keep non-blocking minors in their own trailing section.

## What this skill never does

- Never changes ticket status, labels, or assignee; never approves/merges PRs; never pushes commits.
- Never posts the comment without explicit user approval.
- Never marks an AC verified without runtime observation or an explicitly stated static-only caveat.
- Never re-runs destructive scripts against shared state without first checking their delete/update scope (Phase 4 comes before re-run when in doubt — read the cleanup filter first).

## Edge cases

- **Multiple PRs linked:** ask which one.
- **No acceptance criteria in the description:** derive observable checks from "What to do"/"Outcome" sections, flag that ACs were derived.
- **Runtime environment unavailable** (no emulator config, missing credentials, DB absent): do the static pass, mark affected ACs ⚠️ with the exact missing prerequisite, and list the manual steps in the report — don't silently downgrade to code reading.
- **Deliverable already re-validated by reviewer at runtime:** still re-verify the cheapest independent probe (one recomputation or one UI value); inherit the rest with attribution.
