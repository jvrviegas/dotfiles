---
name: linear-review-comment-summary
description: "Draft and optionally post Linear issue review summary comments for PR validation outcomes, including approval-ready and request-changes cases. Use after reviewing a Linear issue/PR when the user asks for a Linear comment summary, says 'post the summary', 'show me the comment before submitting', 'write the issue comment', 'approval summary', or 'request changes summary'."
compatibility: "Works with the linear skill CLI when posting is requested and approved."
---

# Linear Review Comment Summary

Create a concise Linear issue comment summarizing a code review / validation result. The comment must be suitable for posting as the reviewer, addressed to the assignee/team, and must support both outcomes:

- **Approve / passed / ready**: acceptance criteria verified and no blockers remain.
- **Request changes / needs fixes**: one or more blockers remain, with optional feedback separated.

This skill is about the **comment text**. It does not perform the review itself. If validation is still needed, use the appropriate review/validation skill first.

## Core rules

1. **Always show the comment draft before posting.**
2. **Do not post to Linear until the user explicitly approves the exact draft.**
3. **Write in the user's voice**, not as an AI assistant. Prefer first person singular/plural depending on the user's prior style:
   - "I reviewed..."
   - "I found..."
   - "Can you please address..."
4. **Be factual and concise.** Do not over-explain.
5. **Do not include a recommendation section** unless the user explicitly asks for one.
6. **Separate blockers from optional feedback.**
7. **For request changes**, make the required fixes clear and actionable.
8. **For approval**, avoid sounding like a formal certification; use a natural review-summary tone.
9. **Mention local/manual checks only if they were actually performed or explicitly reported.**
10. **Preserve uncertainty.** If CI was missing or TDD order could not be proven, say so in Notes.

## Inputs to collect

If not already available, ask for the missing items:

- Linear issue identifier, e.g. `PRO-692`
- PR number or URL
- Outcome: `approve` / `passed` / `ready` OR `request changes` / `needs fixes`
- Acceptance criteria validation result
- Blockers, if any
- Optional feedback, if any
- Local checks and CI status, if any
- Notes / caveats, if any

## Output workflow

### Step 1 — Draft only

Produce only the draft in a markdown code block, followed by a short confirmation question:

```markdown
<comment draft>
```

"Confirm and I’ll post this to Linear."

Do not call the Linear CLI in this step.

### Step 2 — Post only after approval

If the user explicitly approves the draft, post it using the linear skill CLI:

```bash
~/.pi/agent/skills/linear/scripts/linear.js save_comment '{"issue":"PRO-XXX","body":"<body with real escaped newlines>"}'
```

After posting, reply with a short confirmation and the Linear comment URL if available.

## Approval / passed template

Use this structure for approval-ready reviews. Remove empty sections.

```markdown
## <ISSUE-ID> Review Summary

I reviewed PR #<PR-NUMBER> for <ISSUE-ID>.

### Result
✅ Acceptance criteria verified  
✅ No blockers found  
✅ No optional/recommended items remaining  
✅ Local validation passed

### Acceptance Criteria
- <criterion/result checked>
- <criterion/result checked>
- <criterion/result checked>

### Local Checks
- `<command>` — passed
- `<command>` — passed

### Notes
- <note/caveat, e.g. PR has no reported CI checks>
- <note/caveat, e.g. TDD order cannot be proven from commit history>
```

Guidance:

- If there were optional items that remain but are non-blocking, change the Result line to: `⚠️ Optional/recommended items noted below` and add an Optional section.
- If no local checks were run, omit `Local Checks` or say `I did not run local checks for this review.` only if relevant.

## Request changes / needs fixes template

Use this structure when blockers remain. Remove empty sections.

```markdown
## <ISSUE-ID> Review Summary

I reviewed PR #<PR-NUMBER> for <ISSUE-ID>.

### Result
❌ Changes requested  
⚠️ <N> blocker(s) found  
<optional line for optional feedback count>  
<optional line for local checks/CI>

### Blockers
1. **<short blocker title>**
   - Issue: <what is wrong>
   - Expected fix: <what needs to change>
   - Evidence: `<file/path>` — <short citation/snippet>

2. **<short blocker title>**
   - Issue: <what is wrong>
   - Expected fix: <what needs to change>
   - Evidence: `<file/path>` — <short citation/snippet>

### Optional / Recommended
- <optional feedback item>
- <optional feedback item>

### Acceptance Criteria Status
- ✅ <met criterion>
- ❌ <unmet criterion and why>
- ⚠️ <partially met/probable criterion and what remains>

### Local Checks
- `<command>` — <passed/failed/not run>

### Notes
- <note/caveat>
```

Guidance:

- Keep blockers actionable; each blocker should say exactly what to fix.
- Do not bury blockers in narrative paragraphs.
- If all acceptance criteria failures are already covered by blockers, keep the AC section short.

## Tone examples

### Approval tone

- "Everything looks good from my side."
- "I didn’t find any blockers."
- "Local validation passed."

### Request changes tone

- "I found a blocker that needs to be addressed before this can move forward."
- "Can you please update this to..."
- "Once this is fixed, I can re-check the PR."

## Posting safety checklist

Before posting, verify:

- The issue identifier is correct.
- The user approved the exact current draft.
- The body contains real newlines, not literal `\\n`, if using a tool that accepts raw markdown.
- No private chain-of-thought or internal analysis is included.
- No unsupported claims are included.
