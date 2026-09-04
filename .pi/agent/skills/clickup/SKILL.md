---
name: clickup
description: "Communicate with ClickUp using a personal-token CLI: discover Workspaces, Spaces, Folders, Lists, users, statuses, tasks, comments, tags, and Custom Fields. Use for ClickUp task and hierarchy workflows."
compatibility: "Requires Node.js 18+ and a ClickUp personal API token in CLICKUP_API_KEY/CLICKUP_TOKEN or macOS Keychain."
---

# ClickUp

Use this skill when the user asks to read or manage ClickUp data. The CLI is dependency-free and uses ClickUp REST API v2.

## Setup

Create a personal token at `ClickUp → Settings → Apps → API Token`. OAuth is not supported in this version.

```bash
export CLICKUP_API_KEY="pk_..."
# CLICKUP_TOKEN is also accepted
```

Credential resolution order is `CLICKUP_API_KEY`, then `CLICKUP_TOKEN`, then the macOS Keychain entry.

Recommended macOS Keychain storage:

```bash
read -s CLICKUP_API_KEY
security add-generic-password -a CLICKUP_API_KEY -s "pi ClickUp Skill" -w "$CLICKUP_API_KEY" -U
unset CLICKUP_API_KEY
```

Check authentication:

```bash
~/.pi/agent/skills/clickup/scripts/clickup.js authenticate
```

Personal tokens use `Authorization: <token>` without `Bearer`. ClickUp OAuth requests use a different bearer-token flow and are intentionally out of scope.

## Usage

```bash
~/.pi/agent/skills/clickup/scripts/clickup.js <command> '<json-arguments>'
```

Examples:

```bash
clickup.js list_spaces '{"workspace":"123"}'
clickup.js list_lists '{"space":"456"}'
clickup.js save_task '{"list":"789","title":"Investigate bug","assignees":[183,184]}'
clickup.js save_task '{"id":"abc123","status":"in progress","description":"Updated"}'
clickup.js save_task_comment '{"task":"abc123","body":"Done"}'
```

Hierarchy: `Workspace → Space → Folder → List → Task`. Names are matched case-insensitively; ambiguous names fail with candidates. IDs are passed through directly. A hierarchy name requires its parent scope; task titles are never used to resolve task IDs. Workspace aliases: `workspace`, `team`, `teamId`.

## Commands

- `authenticate`, `list_workspaces`
- `list_spaces`, `list_folders`, `list_lists`, `list_users`, `list_task_statuses`
- `get_task`, `list_tasks`, `save_task`, `delete_task`, `get_task_by_custom_id`
- `list_task_comments`, `save_task_comment`
- `list_task_tags`, `list_custom_fields`, `set_custom_field_value`

See `references/tools.md` for arguments, filters, endpoint scope, and examples. `PATCH_TRACKER.md` is not needed: the implemented routes are covered by the current ClickUp API v2 reference.
