---
name: cut-release
description: Run a generic release process on any git repo — compute the SemVer bump from Conventional Commits since the last v* tag, curate a CHANGELOG.md section, open a release PR to a detected target branch, then tag and publish a GitHub Release after merge. State-machine style; re-run after each step. Use when the user says "cut-release", "cut a release", "new release", "release a version", "bump the version", or "update the changelog for a release".
---

# cut-release

A re-runnable release state machine. Each invocation detects the current phase from repo
state, performs **only the next step**, then tells the user when to re-run. Never keep a
state file — the repo is the state.

Detailed rules for every phase live in [REFERENCE.md](REFERENCE.md). Read it before
executing a phase for the first time in a session.

## Phase detection

Run these checks in order; the first match is the current phase.

| # | Check | Phase |
|---|-------|-------|
| 1 | No Conventional Commits convention documented anywhere in the repo (CONTRIBUTING.md, CLAUDE.md, README) | **Bootstrap** — document the convention (docs only), then continue to 2 |
| 2 | No open release PR and the latest `v*` tag matches the top CHANGELOG.md version | **Prepare** — compute version, pick target, write changelog, commit, open PR |
| 3 | A release PR (branch `release/vX.Y.Z` or a PR titled `chore(release): vX.Y.Z`) is open | **Waiting** — report the PR URL and stop; user re-runs after merge |
| 4 | Release PR merged but no `vX.Y.Z` tag exists yet | **Publish** — tag the merge commit, push, create the GitHub Release |
| 5 | Tag exists and matches the top changelog version, nothing new since | **Done / nothing to release** — report and stop |

## Phase summaries

**Bootstrap** (docs only — never install commitlint, husky, or CI workflows):
add a Conventional Commits + SemVer section to CONTRIBUTING.md (create the file if
missing), and if the repo has no `v*` tag, propose seeding one. See REFERENCE.md §1.

**Prepare**:
1. Current version = latest `v*` tag (source of truth — never a manifest file).
2. Classify commits since that tag; compute the bump (breaking→major, feat→minor,
   fix→patch). Nothing release-worthy → stop and report, offering an insist-anyway
   escape. See REFERENCE.md §2.
3. **Always** confirm the version with AskUserQuestion: computed bump recommended,
   other bump levels as alternates, Other for arbitrary versions.
4. Detect long-lived branches; **skip the target prompt when only one exists**.
   Otherwise recommend from merge-base + dominant commit type. See REFERENCE.md §3.
5. Write a **curated** changelog section (merge related commits into logical changes,
   drop chore/docs/ci noise) and prepend it — never rewrite existing sections.
   See REFERENCE.md §4.
6. Bump version fields only in manifests that **already** have one.
7. Commit on a `release/vX.Y.Z` branch, push, open the PR to the target. Never push
   directly to the target branch.

**Publish**:
annotated tag `vX.Y.Z` on the merge commit, push the tag; if `gh` is authenticated and
the remote is GitHub, `gh release create` with the changelog section as notes — otherwise
the tag alone completes the release. See REFERENCE.md §5.

## Hard rules

- One version for the whole repo, even in monorepos.
- Existing changelog sections are read-only; match the file's existing format.
- Every prompt to the user goes through AskUserQuestion with a recommended option first.
- Report the outcome of each phase and, when waiting on a merge, say exactly that.
