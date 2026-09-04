---
name: in-review-validation
description: "Validate that a Linear issue in 'In Review' has had its review comments addressed and still satisfies its acceptance criteria. Use when the user says 'validate PRO-XXX', 'check if PR fixes are in', 'in-review check', 'review the in-review ticket', or asks to re-verify a ticket whose assignee just pushed fixes after review feedback. Output is an explicit APPROVED / CHANGES REQUESTED verdict, a markdown table of acceptance criteria + blocker/optional lists with pass/fail per item, and a summary comment draft. Then prompts the user to post the summary on the PR and approve it (when APPROVED) or request changes (when CHANGES REQUESTED) — no writes happen without explicit user confirmation."
---

# In-Review Validation

You take a single Linear issue in **In Review** state and produce a structured pass/fail report comparing the **current** linked PR head against (a) the issue's acceptance criteria and (b) the blocker/optional items raised in the most recent review comment(s). The report ends with an explicit verdict — **APPROVED** or **CHANGES REQUESTED** — and then prompts the user for the follow-up action: post the summary on the PR and approve it (APPROVED), or post the summary and formally request changes (CHANGES REQUESTED). Validation itself is read-only — never push commits or change ticket status — and no comment is posted and no PR review is submitted without the user's explicit confirmation via the Phase 7 prompt. Draft the Linear comment using the standardized template in Phase 6 — never improvise its structure.

## Recommended model

Run this skill with **Claude Opus 4.8** (`claude-opus-4-8`) — the most recommended model for this workflow in terms of following its instructions faithfully while staying cost-effective.

## Inputs

A single Linear issue identifier (e.g. `PRO-688`). If the user gives a different prefix that doesn't resolve, ask them to confirm the team key — never guess.

## Linear scoping

Always scope Linear queries to the team and project configured for the **current repository**, not a hardcoded default. Resolve them in this order before making any Linear call:

1. Check the repo's `AGENTS.md`, `CLAUDE.md`, and `MEMORY.md` for an explicit Linear workspace/team/project declaration (e.g. an "Linear Defaults" section). Use those values verbatim.
2. If multiple are declared, prefer `AGENTS.md` > `CLAUDE.md` > `MEMORY.md`.
3. If none declare it, infer from the issue identifier prefix the user supplied (e.g. `PRO-688` → team key `PRO`) and confirm with the user before proceeding. Never guess a project.
4. Only call `list_teams` / `list_projects` as a last resort when the repo docs are silent and the prefix is ambiguous.
5. If after the steps above the team and/or project still cannot be determined with confidence, **stop and ask the user** which Linear team and project to scope to. Do not proceed with validation until they answer. Never silently fall back to a hardcoded default.

When passing markdown content to Linear tools, send real newlines — never literal `\n`.

## Phase 1: Pull issue + comments + PR

Run these in parallel:

1. `mcp__claude_ai_Linear__get_issue` with `includeRelations: true` to get description (acceptance criteria), state, assignee, and `attachments` (the PR URL is here).
2. `mcp__claude_ai_Linear__list_comments` with `orderBy: createdAt` to get the full review thread.
3. `gh pr view <N> --json state,mergeable,reviewDecision,headRefName,headRefOid,statusCheckRollup,files,commits` for the linked PR.
4. `git fetch origin` so the PR branch is local-readable.

Bail out with a clear message if:
- The issue isn't in **In Review** (warn but continue if user explicitly asked).
- No PR is linked in `attachments`.
- The PR is closed/merged (still produce the report, but flag it).

## Phase 2: Extract review items

Parse the review comment(s) into two ordered lists:

- **Blockers** — items the reviewer marked as required (sections titled "Blockers", "Changes Requested", "Must Fix", or numbered items the reviewer flagged as blocking).
- **Optional / Recommended** — items under "Recommended", "Nits", "Consider", "Suggestion".

If the comment thread has multiple rounds, take the *latest* review comment as the source of truth and merge in any unresolved items from earlier rounds.

For every item, capture: short title, the file/line citation the reviewer gave (if any), and the literal expected fix.

## Phase 3: Pull current code

Create a temporary detached git worktree for the **current head** of the PR branch, then inspect files from inside that worktree:

```bash
mkdir -p .worktrees
git worktree add --detach .worktrees/pr-<N> origin/<headRefName>
```

Use a unique path per PR/session, e.g. `.worktrees/pr-<N>` or `.worktrees/<ISSUE-ID>-pr-<N>`, so multiple validations can run concurrently without branch switching. Prefer `--detach` so the same PR branch can be reviewed in multiple sessions if needed and to avoid modifying local branch state.

From inside the worktree, use normal file/search/test commands (`rg`, `npm test`, `git diff`, etc.) to inspect the current PR filesystem. Do not rely on the reviewer's old line numbers — the assignee has likely changed the file. Search by the symbol/string the reviewer named, not the line number.

When finished, remove the temporary worktree unless the user asks to keep it:

```bash
git worktree remove .worktrees/pr-<N>
git worktree prune
```

## Phase 4: Verify each item

For each blocker and each optional item, classify the status:

- ✅ **Fixed** — the change is unambiguously present in the current file.
- ⚠️ **Partially fixed** — addressed in spirit but with caveats (e.g. used a different mechanism that achieves the goal).
- ❌ **Not addressed** — the original issue still exists.
- ➖ **N/A** — the item was withdrawn or no longer applies.

Cite the current file path and the relevant snippet (a few lines, not a full function) as evidence. If you can't find evidence either way, mark it ⚠️ and say what you couldn't verify.

## Phase 5: Re-verify acceptance criteria


Pull the acceptance criteria checklist from the issue description. For each AC:

- ✅ **Met** — observable in the current code/migration/tests.
- ⚠️ **Probable** — looks correct but requires a runtime check the validator can't perform locally (e.g. "migration runs on clean DB" without a DB available). Say what manual step would close the gap.
- ❌ **Not met**.

Do **not** mark an AC as met just because the issue's checkbox is ticked. Verify against current code.

Also note **regressions or new issues** introduced by the latest fix commits — anything that wasn't in the original review but matters now (e.g. CI failing, a new column added without a comment, a renamed index that breaks a downstream migration).

## Phase 6: Output report

Produce a single markdown response with this exact structure (no preamble, no closing summary unless something is broken). Include the Linear issue comment draft at the end for user approval; do not post it automatically.

The report **must open with an explicit, unmissable RESULT line** — the first thing the reader sees, before the PR/CI metadata. There are exactly two verdicts. Pick one and delete the other from the template:

- ✅ **APPROVED** — zero blockers remaining, no ❌ anywhere, and every acceptance criterion is ✅ Met or ⚠️ Probable. If any AC is ⚠️ Probable (needs a manual/runtime check the validator can't do locally), append the qualifier `(pending manual checks)` to the RESULT line and list the required steps in the "Manual checks" section — the follow-up prompt must warn about them before approving.
- ❌ **CHANGES REQUESTED** — any blocker is ❌/⚠️, or any AC is ❌ Not met, or a new regression was introduced.

The RESULT line, the Verdict counts, and the Recommendation must all agree — never a green RESULT with open blockers. Follow the RESULT with a one-line justification citing the counts that drove it.

For the `Linear issue comment draft` section, use the standardized template in "Linear comment template" below — same structure every time, no exceptions.

```
# <ISSUE-ID> — In-Review Validation

## ✅ RESULT: APPROVED  —  or  —  ❌ RESULT: CHANGES REQUESTED

> One-line justification, e.g. "All 3 blockers fixed and all ACs met." / "2 blockers still open." / "All blockers fixed; 1 AC needs a manual DB run to confirm (pending manual checks)."

**PR:** #<N> (<headRefOid short>) · **CI:** <X/Y green> · **Review decision:** <APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED>

## Acceptance Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | <text>    | ✅/⚠️/❌ | <file:line or short snippet> |
| ... |

## Blockers

| # | Item | Status | Evidence |
|---|------|--------|----------|
| B1 | <short title> | ✅/⚠️/❌ | <citation> |
| ... |

## Optional / Recommended

| # | Item | Status | Evidence |
|---|------|--------|----------|
| O1 | <short title> | ✅/⚠️/❌ | <citation> |
| ... |

## Verdict

- **Result:** ✅ APPROVED · ❌ CHANGES REQUESTED (must match the RESULT line at the top)
- **Blockers remaining:** <count>
- **Optional remaining:** <count>
- **New issues:** <count> (or "none spotted")
- **Recommendation:** <post summary + approve PR (APPROVED) · post summary + request changes on PR (CHANGES REQUESTED)>

## Manual checks the validator could not perform

- <bullet list, e.g. running migrations against a real DB>

## Linear issue comment draft

> Awaiting user approval before posting this to Linear.

```markdown
<comment draft following the "Linear comment template" section below>
```
```

Keep evidence cells short — one file path + a one-line snippet. Long quotes belong in the chat, not the table.

## Linear comment template

The Linear comment is written in the reviewer's first-person voice, addressed to the developer. Professional, simple, objective — no filler praise, no sign-off. Use this exact structure every time:

```markdown
## Code Review - ✅ APPROVED

**PR:** [#<N>](<pr-url>) · **Commit:** <short SHA> · **CI:** <passing|failing|pending>

<1–2 sentence first-person summary: what I reviewed and the bottom line. Acknowledge resolved prior blockers here (e.g. "All three blockers from my previous review are resolved."). If any AC is ⚠️, state that a manual check is needed before merge and point to the ⚠️ item(s) below.>

### Acceptance Criteria

- ✅ <criterion> — <why it is met: file/behavior evidence>
- ⚠️ <criterion> — <looks correct; the manual/runtime check needed to confirm>
- ❌ <criterion> — <why it is not met>

### Blockers

- <open blocker, with why it blocks approval>
- New: <issue introduced by the fix commits>

### Suggestions

- <prior optional item still unaddressed (carried over)>
- <new non-blocking observation>

<closing line>
```

Rules:

- **Title is strictly binary**: `## Code Review - ✅ APPROVED` or `## Code Review - ❌ CHANGES REQUESTED`. Never add qualifiers (no "(pending manual checks)"), never invent a third variant. It must match the report's RESULT line.
- **Acceptance Criteria**: one line per AC, always ending with an em-dash reason — evidence for ✅, the pending manual check for ⚠️, what's missing for ❌. List every AC.
- **Blockers** = what currently blocks approval only: unfixed prior blockers plus new regressions (prefix new ones with `New:`). Fixed prior blockers are acknowledged in the summary sentence, not listed. When empty, the section body is exactly `None.` — the section heading always appears.
- **Suggestions** = prior optional items still unaddressed (carried over — they stay optional, never escalate to blockers) plus new non-blocking observations. When empty: `None.` — the heading always appears.
- **Closing line** (verdict-dependent, one line): APPROVED → `Approving the PR.` (when ⚠️ ACs exist, extend it: `Approving the PR — please run the manual check(s) above before merging.`); CHANGES REQUESTED → `Please address the blockers above and I'll re-review.`
- **Consistency**: APPROVED requires Blockers to be `None.`; CHANGES REQUESTED requires at least one blocker listed.
- On a first review round (no prior review comment), the same template applies — Blockers/Suggestions simply contain only new findings.

This template applies to the Linear comment only; the GitHub PR review body in Phase 7 keeps its own format (RESULT line, justification, tables).

## Phase 7: Prompt for follow-up action

Immediately after presenting the report, prompt the user with `AskUserQuestion` for the follow-up action. The options depend on the verdict:

**When the verdict is ✅ APPROVED**, ask "Post the validation summary on the PR and approve it?" with options:

1. **Post summary + approve PR (Recommended)** — post the summary as the PR review body and approve: `gh pr review <N> --approve --body-file <summary.md>`.
2. **Post summary only** — comment the summary on the PR without a formal review: `gh pr comment <N> --body-file <summary.md>`.
3. **Skip** — do nothing on GitHub.

If the RESULT carried the `(pending manual checks)` qualifier, say so in the question text and do **not** mark option 1 as Recommended — the user must knowingly approve with manual checks outstanding.

**When the verdict is ❌ CHANGES REQUESTED**, ask "Post the validation summary on the PR and request changes?" with options:

1. **Post summary + request changes (Recommended)** — post the summary as the PR review body and formally request changes: `gh pr review <N> --request-changes --body-file <summary.md>`.
2. **Post summary only** — comment the summary on the PR without a formal review: `gh pr comment <N> --body-file <summary.md>`.
3. **Skip** — do nothing on GitHub.

In both cases, also ask (same `AskUserQuestion` call, second question) whether to post the Linear issue comment draft to the Linear issue.

The PR review/comment body is the validation summary: RESULT line, justification, the blockers/optional tables (or a compact list when short), and any manual checks. Write it to a scratchpad file and pass it via `--body-file` so markdown survives shell quoting. Execute only the actions the user selected — a skipped or dismissed prompt means no writes at all. Note: `gh pr review --approve` fails if the PR author is the current `gh` user; report that error verbatim and fall back to offering "post summary only".

## What this skill never does

- Never pushes commits.
- Never runs `gh pr review` or `gh pr comment` except as the action the user explicitly selected in the Phase 7 prompt.
- Never updates the Linear ticket status, assignee, or labels.
- Never posts a comment on Linear or GitHub unless the user explicitly approves it via the Phase 7 prompt (or approves the draft afterward).
- Never marks an AC pass just because the issue description's checkbox is ticked.
- Never silently re-runs reviewer suggestions as new code edits — this skill is read-only.

## Edge cases

- **Multiple PRs linked:** ask the user which one to validate.
- **No review comment on the issue:** still validate ACs against the PR head and report 0 blockers / 0 optional.
- **Reviewer left review on GitHub instead of Linear:** also pull `gh api repos/<owner>/<repo>/pulls/<N>/reviews` and `/comments`, and merge into the blocker/optional split.
- **Spec uses snake_case but project convention is camelCase (or vice versa):** flag it as a note, don't mark it failed — verify against the project's actual convention by reading a neighboring migration or entity.
