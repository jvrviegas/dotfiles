---
name: linear-implementation-plan
description: Creates repository-specific implementation plans from Linear issues, strictly limited to the issue's requirements and acceptance criteria. Use when asked to plan, analyze, or create an implementation plan for a Linear issue such as PRO-1566, especially when the plan must be written under docs/plans/.
compatibility: Requires access to the target Git repository and authenticated Linear tooling.
---

# Linear Implementation Plan

Create an evidence-based implementation plan from one Linear issue. Do not implement the issue.

## Inputs

Required: Linear issue identifier. Default output directory: `docs/plans/`.

If the identifier is missing, ask for it. Ask other questions only when unresolved ambiguity would materially change the plan.

## Workflow

1. **Retrieve the issue**
   - Use an available Linear integration. In Pi, load the `linear` skill and use its CLI when needed:
     `~/.pi/agent/skills/linear/scripts/linear.js get_issue '{"id":"ISSUE-ID"}'`.
   - Read the description, acceptance criteria, comments, relations, status, and linked documents.
   - Retrieve related issues only to establish dependencies, contracts, and scope boundaries. Never import their requirements into this issue.

2. **Establish strict scope**
   - Treat the issue description and acceptance criteria as authoritative.
   - Separate required work from dependencies, follow-ups, and adjacent issues.
   - State explicit exclusions. Do not add refactors, hardening, UI, abstractions, environments, or operational work unless required by an acceptance criterion.
   - Flag contradictions or missing decisions instead of inventing behavior.

3. **Inspect the repository**
   - Read `.notebook/INDEX.md` if present, relevant project docs, and existing plans.
   - Check `git status` before writing; do not modify or overwrite unrelated work.
   - Trace only code, configuration, deployment, and tests directly relevant to the issue.
   - Record exact file paths, existing patterns, constraints, and gaps. Distinguish current facts from proposed changes.
   - Consult official technical documentation only when the plan depends on behavior not provable from the repository.

4. **Design the minimum solution**
   - Map every proposed change to an issue requirement.
   - Preserve existing architecture and conventions where they satisfy the issue.
   - Identify operator/manual actions separately from code changes.
   - Respect issue sequencing: create integration points for blocked work, but do not implement another issue or add placeholder production behavior.

5. **Write the plan**
   - Create `docs/plans/<lowercase-issue-id>-<short-slug>.md` unless the user specifies another name.
   - Follow [references/plan-template.md](references/plan-template.md).
   - Every task must name files or operational resources, describe the minimum change, and include observable verification.
   - Include an acceptance-criteria traceability table with no uncovered criterion.

6. **Validate**
   - Re-read the issue and remove anything not required to satisfy it.
   - Confirm linked issues have not leaked into scope.
   - Confirm commands contain no real secrets or destructive actions.
   - Run `git diff --check -- <plan-path>` and inspect `git status --short`.
   - Report the created path and mention pre-existing uncommitted files that were left untouched.

## Quality rules

- Never claim a file, endpoint, service, or behavior exists without repository evidence.
- Never put live credentials, secret values, or sensitive derived values in a plan.
- Prefer exact paths, symbols, commands, and verification outcomes over generic steps.
- Use implementation order, dependencies, and rollout gates where relevant; avoid estimates unless requested.
- Tests must prove acceptance behavior, including failure paths explicitly required by the issue.
- Keep the plan self-contained but concise. Link existing specs instead of copying them.
- Do not update Linear, source code, `.notebook/`, or unrelated documentation unless explicitly requested.
