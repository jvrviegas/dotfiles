# Linear Project Update Methodology

Distilled from Linear's docs ([Initiative and project updates](https://linear.app/docs/initiative-and-project-updates)) and their write-up ([How we built project updates](https://linear.app/now/how-we-built-project-updates)).

## Core principles

1. **Qualitative over quantitative.** Linear explicitly rejected velocity-metric-driven status: "project progress is not something that can be predicted based on quantitative data alone. It needs qualitative input from the project team." Data (issues closed, milestone %) is supporting evidence, not the update itself.
2. **Brief, almost like a tweet.** The reader is often unfamiliar with project details — an exec scanning a roadmap feed or a Slack channel. Every sentence must earn its place.
3. **Retrospective + forward-looking.** Combine "here's what happened since last update" with "based on what I know today, I think this project will/won't finish on time."
4. **Delta, not recap.** Cover changes since the last update: delays, target-date changes, new leads, milestone progress, scope changes.
5. **Meet readers where they are.** Updates get consumed in Linear, roadmap feeds, and Slack — write so the text stands alone without opening the project.

## Anatomy of an update

1. **Health indicator** — On Track / At Risk / Off Track. The signal people scan first.
2. **Narrative** — rich text, structured roughly as:
   - **Headline sentence**: the most important thing right now.
   - **Progress**: what shipped / moved since last update.
   - **Risks / blockers**: what threatens the plan, who owns resolution, any asks.
   - **Next**: what happens before the next update.

For **initiative updates**, stay one level higher: goal alignment and the state of contributing projects, not issue-level detail. Ownership and target-date changes are included automatically by Linear — reference them, don't restate mechanically.

## Cadence

Weekly is the norm (Linear posts Fridays). If the project has reminder schedules configured, match them. An update is worth posting even when the news is "no change — still on track," but keep that one to 1–2 sentences.

## Health status honesty

- Don't let a project sit On Track until the deadline suddenly "surprises" everyone. At Risk exists precisely to surface trouble early, when it's cheap to fix.
- Moving to At Risk / Off Track requires naming *why* and *what would put it back on track*.
- Recovering to On Track deserves a sentence on what changed.

## Examples

**Good — On Track:**

> Auth migration is on schedule for the Mar 14 target. SSO flows shipped to staging this week and passed security review. Remaining work is the session-revocation edge cases (2 issues). No blockers.

**Good — At Risk:**

> Flagging at risk: the payments provider's sandbox has been down since Tuesday (their ticket #4821), which blocks end-to-end testing. Core checkout flow is code-complete. If sandbox access returns by Monday we hold the Apr 2 date; otherwise expect ~1 week slip. Ask: @dana to escalate with the provider.

**Bad (metrics dump, no judgment):**

> 14 issues closed, 6 in progress, 3 added. Velocity 21 points. Milestone 2 at 68%.

**Bad (recap, no delta, jargon):**

> This project implements the new ingestion pipeline using the KFB adapter pattern as discussed. We continued working on PRO-231, PRO-233, PRO-240, PRO-244 and had several syncs about the DLQ approach.

## Source-gathering hints

- **Previous updates** are the single most valuable input: they set the baseline, tone, and open threads to close ("last week we flagged X — resolved?").
- **Linear**: filter issues by project + updated-since-baseline; check milestone target dates vs. today; scan comments on blocked/urgent issues.
- **Slack**: decisions and risk signals live in threads before they reach Linear. Search the project name and the team's channel; read threads with real discussion, skip bot noise.
- **Gmail**: external signals — customer commitments, vendor delays, stakeholder pressure — that Linear won't show.
- Attribute claims when drafting for review ("per Slack thread in #team-payments", "per Acme email Thu") so the user can verify before posting.
