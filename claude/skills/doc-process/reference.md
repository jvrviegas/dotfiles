# Documentation Process — Requirements & Functional Specs

*Owner: Product · Status: Active (piloting on DMS) · Last updated: 14 July 2026*

## Why this exists

Until now, expected product behavior often wasn't written down before build, documentation that did exist drifted from reality, and what was written was too vague for development and QA to work from. This process fixes that with two document layers, each with a different job and lifespan.

## The two-layer model

| | Layer 1 — Feature Spec | Layer 2 — Living Functional Spec |
| :-- | :-- | :-- |
| **What it is** | A short PRD-like document per feature | The current behavior of the product, per area |
| **Lifespan** | Dies when the feature ships | Permanent, always up to date |
| **Purpose** | Alignment before build; client sign-off | Source of truth for behavior; reference for QA, support, onboarding; context for AI tools |
| **Lives in** | Linear, as a document attached to the project | Git repo, `docs/spec/` (markdown files) |
| **Owner** | PM | PM (content) + engineers (updates via PR) |
| **Length** | Maximum 2 pages — hard rule | As long as needed, split by product area |

**The key rule: behavior is only true in Layer 2.** A feature spec is a proposal. Once shipped, its behaviors are merged into the living spec and the feature spec is archived. Anyone asking "how does X work?" goes to the living spec — never to old PRDs.

## Where to find everything (DMS pilot)

- **Living spec (readable site, for PMs and anyone non-technical):** [dms-functional-spec.procimo.com](https://dms-functional-spec.procimo.com) — sign in with your @procimo.com email (a PIN code is emailed to you; no account needed). The site updates automatically whenever the spec changes.
- **Living spec (source, for engineers):** `dms-backend/docs/spec/*.md`
- **Templates:** Feature Spec (Layer 1): make a copy of "00_TEMPLATE — Feature Spec (Layer 1)" in 04_PRODUCT / 03_PRD (Specs). Functional Spec area file (Layer 2): `_template.md` in `dms-backend/docs/spec/`

## The workflow

### 1. Before build

- The PM drafts a Feature Spec from the Linear issue(s) and discussion context. Use AI to produce the first draft; the PM edits rather than writes from scratch.
- Behaviors are written as testable acceptance criteria: "Given [context], when [action], then [outcome]" or "When X, the system does Z". No narrative-only requirements.
- The tech lead reviews for feasibility. When applicable, the spec goes to the client for sign-off.
- Build does not start until the acceptance criteria are agreed. Small changes and bug fixes skip Layer 1 entirely — they go straight to step 3.

### 2. During build

- The Feature Spec is the reference. Scope changes are edited into the spec with a changelog line — never agreed only verbally.
- QA tests against the acceptance criteria.

### 3. On ship — the anti-staleness mechanism

- **The PR that changes behavior must update `docs/spec/` in the same PR.** This is part of the definition of done and is checked in code review, with the same discipline as tests.
- The PM reviews the spec diff for correctness and language (via the published site or the PR).
- The Feature Spec is marked Shipped/Archived in Linear, with a link to the living-spec section it merged into.

### 4. Ongoing

- The living spec is the context fed to AI coding tools, test generation, and technical documentation.
- Client-facing behavior documentation is exported from the living spec — never written separately.

## Who does what

| Role | Responsibility |
| :-- | :-- |
| PM | Drafts and owns Feature Specs; reviews living-spec changes; runs client sign-off; resolves ⚠️ "confirm intent" flags |
| Tech lead | Reviews Feature Specs for feasibility; blocks PR merges that change behavior without updating the spec |
| Engineers | Update the living spec in the same PR that changes behavior; write rules, not narrative |
| QA | Tests against acceptance criteria; flags any mismatch between spec and actual behavior |

## How to write behaviors (both layers)

- One rule per bullet, numbered with the area prefix (e.g. `COMP-14`, `ENT-4`) so it can be referenced from tickets, tests, and support answers.
- Every rule must be testable: "When [condition], the system [does Z]." If you can't imagine the test, rewrite the rule.
- Known-wrong behavior goes in the "Known gaps and quirks" section — documented so nobody mistakes a bug for intended design, with a Linear link if a fix is planned.
- Don't append changelogs to the living spec — git history is the changelog.

## Engineer's PR checklist

- Does this PR change any user-visible behavior, validation, notification, email, permission, or scheduled job? → Update the affected rules in `docs/spec/` in this PR.
- New feature shipped? → Merge the Feature Spec's behaviors into the living spec (keep the numbering scheme) and archive the Feature Spec in Linear.
- Behavior removed? → Delete the rule. Never leave rules describing behavior that no longer exists.

## Failure modes we're watching for

- **Specs get heavy again** → cut sections; the 2-page limit on Feature Specs is a hard rule.
- **Spec updates skipped in PRs** → tech lead blocks the merge; treat exactly like missing tests.
- **Old PRDs cited as truth** → archive aggressively; PRDs link forward to the living spec.
- **Living spec written as narrative** → behaviors must be testable rules, one per bullet.

## Current status (July 2026)

The DMS living spec was bootstrapped by reverse-engineering current behavior from the code. Every rule is in **draft** until PM review: rules marked ⚠️ need an explicit confirm/correct decision, and each area's "Known gaps and quirks" section lists suspected bugs to triage into Linear. Once the DMS pilot has run through 2–3 features, this process rolls out to the other products.
