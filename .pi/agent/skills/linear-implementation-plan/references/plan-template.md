# Implementation plan template

Adapt sections to the issue; omit irrelevant sections rather than adding filler.

```markdown
# ISSUE-ID — Issue title implementation plan

Linear: [ISSUE-ID](linear-url)  
Status at planning: Status  
Primary specification: [path or link]

## Objective

One paragraph defining the exact required outcome.

## Scope boundary

### Included

- Work directly required by the issue.

### Excluded

- Adjacent behavior owned by linked issues or not required by acceptance criteria.

## Current-state findings

- Evidence-based repository facts with file links or symbol names.
- Missing prerequisites or implementation gaps.
- Relevant deployment/runtime constraints.

## Design

Describe the minimum proposed design and why it fits existing patterns. Separate facts from decisions. Add subsections only for meaningful components or rollout behavior.

## Implementation tasks

### 1. Task outcome

Files/resources:

- `exact/path`

Changes:

- Specific minimum change.

Verification:

- Observable result, test, or command proving completion.

### 2. Next task

Repeat as needed in dependency order.

## Acceptance-criteria traceability

| Acceptance criterion | Plan coverage |
|---|---|
| Concise criterion text | Task N / verification step |

Every criterion must map to at least one task and verification step.

## Final verification

Automated commands and environment-specific/manual checks. State prerequisites that prevent immediate verification.

## Risks and controls

Only issue-specific delivery risks, each paired with a concrete control. Do not turn this into a general hardening backlog.
```

## Task-writing checklist

Each task answers:

1. What required outcome does it deliver?
2. Which exact files, symbols, services, or resources change?
3. What is the smallest necessary change?
4. How is success observed independently?
5. Which acceptance criterion does it satisfy?

## Scope audit

Before saving, remove any item whose justification is only:

- "while we are here";
- generic best practice without an issue requirement;
- a requirement from a related issue;
- speculative future flexibility;
- cleanup of pre-existing debt;
- an unsupported assumption about the codebase or infrastructure.
