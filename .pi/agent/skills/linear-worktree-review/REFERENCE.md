# Review File Template

```markdown
# <ISSUE-ID> — Implementation Review

**Current verdict:** ✅ Approved | ❌ Changes Requested  
**Last reviewed:** <date>  
**Worktree:** `<path>`  
**Reviewed commit:** `<short-sha>`  
**Linear state:** <state>  
**PR:** <URL/number or None linked>

## Result

<One-line reason grounded in blocker and criterion counts.>

## Acceptance Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | <verbatim or faithful criterion> | ✅ Met / ⚠️ Probable / ❌ Not met | `<path:line>` and concise explanation |

## Blockers

### B1 — <Title>

**Status:** ❌ Open

<Observed behavior, expected behavior, impact, and evidence.>

**Required change:** <Concrete outcome, without implementing it.>

Use `None.` when empty.

## Optional Recommendations

### O1 — <Title>

<Concise recommendation and evidence.>

Use `None.` when empty.

## Validation Performed

| Check | Result |
|-------|--------|
| `<exact command>` | <result> |

## Verdict

- **Result:** ✅ Approved | ❌ Changes Requested
- **Blockers remaining:** <count>
- **Optional recommendations:** <count>
- **Checks not performed:** <list or None>
- **Recommendation:** <next action>

## Re-review — <date>

**Previous commit:** `<sha>`  
**Current commit:** `<sha>`  
**Verdict:** ✅ Approved | ❌ Changes Requested

### Previous Findings

| Item | Previous status | Current status | Evidence |
|------|-----------------|----------------|----------|
| B1 | ❌ Open | ✅ Resolved / ⚠️ Partial / ❌ Open / ➖ N/A | `<path:line>` |

### Regression Check

| Acceptance criterion | Status | Evidence |
|----------------------|--------|----------|
| AC1 | ✅/⚠️/❌ | `<path:line>` |

### New Findings

<New blockers and optional findings, or `None.`>

### Validation

| Check | Result |
|-------|--------|
| `<exact command>` | <result> |

### Re-review Verdict

<Counts, verdict reason, and next action.>
```

## Evidence Rules

- Prefer current `path:line` citations and one short snippet.
- Distinguish runtime evidence from static inspection.
- A test passing proves only the scenario it actually asserts.
- Flag tests that mock away the behavior they claim to verify.
- Note unavailable services, migration runs, or manual checks explicitly.
- Compare introduced lint/test failures against the base where practical; do not attribute unrelated baseline failures to the implementation.

## Re-review Preservation Rules

- Never erase the original findings or validation results.
- Update the top metadata and current verdict while retaining historical sections.
- Append re-reviews chronologically.
- If an old blocker is fixed but a regression appears, mark the old blocker resolved and add a new blocker.
- Include both previous and current SHAs so the reviewed delta is reproducible.
