---
name: project-update
description: Write and post Linear project or initiative updates following Linear's methodology — a health signal (On Track / At Risk / Off Track) plus a brief, qualitative, delta-focused narrative. Gathers context from Linear (issues, milestones, previous updates), Slack discussions, and Gmail threads. Use when the user asks to write, draft, or post a project update, status update, initiative update, or weekly update.
---

# Project Update

Write a Linear-style update: **health indicator + short narrative**. Brief and to the point — "almost like a tweet" — readable by someone unfamiliar with project details. Qualitative judgment from the team beats velocity metrics. See [REFERENCE.md](REFERENCE.md) for the full methodology and examples.

## Tools

Linear/Gmail/Slack MCP tools may be deferred. Load what you need in ONE ToolSearch call, e.g.:

```
select:mcp__claude_ai_Linear__list_projects,mcp__claude_ai_Linear__get_project,mcp__claude_ai_Linear__get_status_updates,mcp__claude_ai_Linear__list_issues,mcp__claude_ai_Linear__list_milestones,mcp__claude_ai_Linear__save_status_update,mcp__claude_ai_Slack__slack_search_public_and_private,mcp__claude_ai_Slack__slack_read_thread,mcp__claude_ai_Gmail__search_threads,mcp__claude_ai_Gmail__get_thread
```

## Workflow

### 1. Identify the target

- Read the working directory's `CLAUDE.md` and `AGENTS.md` (also check repo root if in a subdirectory) and look for a Linear project or initiative reference — a project name, Linear URL, or project ID.
- Found a reference → resolve it with `list_projects` / `list_initiatives` and confirm the match in one line ("Using project **X** from CLAUDE.md").
- **No reference in either file → stop and ask the user which project/initiative to update.** List active ("In Progress") projects as options. Do not guess from the repo name or pick one silently.
- Fetch the project (`get_project`) and its **previous status updates** (`get_status_updates`). The last update's date and health define the baseline: the new update covers the delta since then. No previous update → cover roughly the last week.

### 2. Gather context (run sources in parallel)

- **Linear**: issues in the project updated since the baseline (`list_issues`), milestone progress (`list_milestones`), comments on recently active or blocked issues. Note: completed vs. added scope, target-date or lead changes, blocked issues.
- **Slack**: `slack_search_public_and_private` for the project name / key terms since the baseline date; read relevant threads. Look for decisions, blockers, risks raised in discussion.
- **Gmail**: `search_threads` with project name / stakeholder terms and `after:` the baseline date. Look for external dependencies, customer/stakeholder signals, vendor delays.

Only pull what changes the story — skip routine noise.

### 3. Assess health

| Status | Choose when |
|---|---|
| **On Track** | Progressing as expected; current target date still credible |
| **At Risk** | Obstacles emerging that could slip the date if unaddressed |
| **Off Track** | Significant delays or issues; needs intervention or a new target date |

Blend retrospective ("what happened") with forward-looking judgment ("based on what I know today, will this finish on time?"). When evidence conflicts, flag it to the user rather than picking silently.

### 4. Draft

Use the structure in [REFERENCE.md](REFERENCE.md). Rules:

- 3–8 sentences total. Delta since last update, not a project recap.
- Lead with the single most important fact.
- Name blockers and risks plainly, with owners/asks where relevant.
- Mention target date, lead, or scope changes explicitly.
- Write for a reader outside the project. No internal jargon or issue-ID soup (link 1–3 key issues at most).

### 5. Review and post

Show the user the draft with the proposed health status and cite where key claims came from (Linear issue, Slack thread, email). **Never post without explicit approval.** After approval, post with `save_status_update` (health + body, correct `projectId`/`initiativeId`). Confirm with the update URL.
