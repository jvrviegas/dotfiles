# cut-release — detailed phase rules

## §1 Bootstrap (docs only)

Trigger: no Conventional Commits convention documented in CONTRIBUTING.md, CLAUDE.md, or
README.md.

- Append (or create CONTRIBUTING.md with) a "Commit messages" section documenting:
  the `<type>(<scope>): <summary>` format, the bump mapping (`feat!`/`BREAKING CHANGE`
  → major, `feat` → minor, `fix` → patch, `chore`/`docs`/`refactor`/`test`/`ci` → no
  release impact), and that releases derive the version and changelog from commits.
- Never install commitlint, husky, git hooks, or CI workflows. Docs are the entire
  bootstrap; the skill itself is the enforcement whenever a release runs.
- If the repo has **no `v*` tag at all**, propose via AskUserQuestion either seeding
  `v0.1.0` on the current HEAD of the default branch (recommended) or deriving an
  initial version from the whole history. The first release then proceeds from that tag.
- Commit the docs change separately (`docs: document conventional commits and semver`),
  then continue into Prepare in the same run.

## §2 Version computation

- **Source of truth**: the latest tag matching `v[0-9]*` by version sort
  (`git tag --list 'v*' --sort=-v:refname | head -1`). Manifest version fields are
  mirrors, never the source.
- Collect commits: `git log <last-tag>..HEAD --no-merges` on the branch being released.
- Parse each subject as Conventional Commits. Bump = highest of:
  - `!` after type/scope, or `BREAKING CHANGE:` footer → **major**
  - `feat` → **minor**
  - `fix` → **patch**
  - `chore`, `docs`, `refactor`, `test`, `ci`, `style`, `build`, `perf` (unless
    breaking) → no release impact
- **Unparseable commits**: never abort. Read the message and, when still unclear, the
  diff, and classify them yourself. Flag them in the version prompt, e.g. "3 commits
  didn't follow the convention; I read them as fix". They count toward the bump under
  your classification.
- **Nothing release-worthy** (only no-impact commits, or no commits at all): stop and
  report "nothing to release since <tag>". Offer an AskUserQuestion escape to force a
  patch release anyway, warning it may tag content identical to the last release.
- Version prompt (always shown): recommended option = computed bump with the driving
  commits named ("2 feats → minor: v1.2.0"); alternates = the other bump levels with
  their resulting versions; the built-in Other covers prereleases and jumps like 1.0.0.

## §3 Target branch detection

- Enumerate long-lived branches: intersect local + remote branches with the
  conventional set `main`, `master`, `develop`, `development`, `staging`, `release/*`
  (only long-lived `release` branches, not the skill's own `release/vX.Y.Z`).
  Cross-check against CONTRIBUTING.md / CLAUDE.md / README branch-flow docs when they
  exist — docs win over guessing.
- **Exactly one long-lived branch → skip the prompt entirely**; it is the target.
- Several → prompt with AskUserQuestion, recommending from two signals:
  - **Merge-base**: where the current branch forked from. Forked from `main` → hotfix
    path, recommend `main`. Forked from `development`/`develop` → promotion path,
    recommend the next branch up the chain (usually `staging` when it exists).
  - **Dominant commit type**: all `fix` → supports the hotfix reading; any `feat` →
    supports the normal promotion flow.
  - When the signals disagree, say so in the option descriptions and let the user pick.

## §4 Changelog upsert

- **Curated, not mechanical.** Group the release-worthy commits into logical changes
  (repos with one-commit-per-file conventions produce several commits per change —
  merge them). Read diffs when subjects are unclear. Drop chore/docs/ci noise. Write
  user-facing bullets — what changed for someone using the software, not what the
  commit did to the code.
- Section shape (new file or Keep a Changelog file):

  ```markdown
  ## [X.Y.Z] - YYYY-MM-DD

  ### Added
  ### Changed
  ### Fixed
  ```

  Map `feat` → Added (or Changed when it alters existing behaviour), `fix` → Fixed,
  breaking notes get a `### Breaking` subsection at the top. Omit empty subsections.
- **Upsert rules**:
  - File missing → create it with the Keep a Changelog header/intro, then the section.
  - File exists → prepend the new section above the previous latest version, below the
    header/intro. Everything below is **read-only** — never reword, reorder, or
    reformat existing sections.
  - File uses a recognizably different format (e.g. conventional-changelog output) →
    write the new section in **that** format instead of imposing Keep a Changelog.
  - An `## [Unreleased]` section exists → fold its bullets into the new version
    section (preserving their wording) and leave an empty `[Unreleased]` heading.
- Get today's date from the environment/context, never from memory.

## §5 Release PR, tag, and GitHub Release

- Branch: `release/vX.Y.Z` cut from the branch being released. Commit the changelog
  (and any manifest bumps) following the repo's commit conventions — check for
  repo-specific rules like one-commit-per-file. Commit subject:
  `chore(release): vX.Y.Z`.
- Manifest bumps: only update `version` fields that **already exist** (package.json,
  pyproject.toml, Cargo.toml, …). Never introduce a version field.
- Open the PR to the chosen target with the changelog section as the body. Never push
  to the target branch directly, even when it is unprotected.
- **Publish** (after the user re-runs post-merge):
  - Find the merge commit of the release PR on the target branch.
  - `git tag -a vX.Y.Z -m "vX.Y.Z" <merge-commit>` and push the tag.
  - If the remote is GitHub and `gh auth status` succeeds:
    `gh release create vX.Y.Z --title "vX.Y.Z" --notes <changelog section>`.
  - Otherwise the pushed tag completes the release — say so explicitly rather than
    erroring.
- Multi-branch repos: a release merged to an intermediate branch (e.g. `staging`) is
  tagged there only if the repo's docs say so; by default tag only when the release
  reaches the branch its docs call production. When unsure, ask.
