---
name: linear
description: "Communicate with Linear from pi using a CLI with Linear MCP-style tools: list/get/save issues, projects, milestones, initiatives, comments, teams, users, labels, cycles, documents, attachments, customers, and status updates. Use for Linear issue tracking, planning, triage, project management, and posting Linear comments."
compatibility: "Requires Node.js 18+ and a Linear API key in LINEAR_API_KEY/LINEAR_TOKEN or macOS Keychain."
---

# Linear

Use this skill whenever the user asks to read, create, or update Linear data.

Pi does not provide MCP tools directly, so this skill exposes a local CLI with Linear MCP-style tool names for the supported Linear GraphQL operations. The CLI uses Linear's GraphQL API. Remaining parity gaps are tracked in `PATCH_TRACKER.md`.

## Setup

1. Create a Linear personal API key: Linear → Settings → API → Personal API keys.
2. Store it securely. Recommended on macOS, use Keychain:

```bash
read -s LINEAR_API_KEY
security add-generic-password -a LINEAR_API_KEY -s "pi Linear Skill" -w "$LINEAR_API_KEY" -U
unset LINEAR_API_KEY
```

Alternative: export it in your shell:

```bash
export LINEAR_API_KEY="lin_api_..."
# LINEAR_TOKEN is also accepted
```

Check auth:

```bash
~/.pi/agent/skills/linear/scripts/linear.js authenticate
```

## Usage

Run any implemented Linear MCP-style tool by name:

```bash
~/.pi/agent/skills/linear/scripts/linear.js <tool-name> '<json-arguments>'
```

Examples:

```bash
# Get an issue by identifier or UUID
~/.pi/agent/skills/linear/scripts/linear.js get_issue '{"id":"CP-299"}'

# List issues
~/.pi/agent/skills/linear/scripts/linear.js list_issues '{"team":"Carbon Products","project":"Dash2Zero","state":"Triage","limit":20}'

# Create an issue
~/.pi/agent/skills/linear/scripts/linear.js save_issue '{"team":"Carbon Products","project":"Dash2Zero","title":"Fix login bug","description":"Details...","state":"Triage","labels":["bug"]}'

# Update an issue
~/.pi/agent/skills/linear/scripts/linear.js save_issue '{"id":"CP-299","state":"Done"}'

# Post a comment
~/.pi/agent/skills/linear/scripts/linear.js save_comment '{"issue":"CP-299","body":"Implemented in PR #123."}'
```

## Implemented MCP-style tools

The CLI implements these Linear MCP-style tool names:

- `authenticate`
- `create_attachment`, `create_attachment_from_upload`, `delete_attachment`, `get_attachment`, `prepare_attachment_upload`
- `create_issue_label`, `list_issue_labels`, `list_project_labels`
- `delete_comment`, `list_comments`, `save_comment`
- `delete_customer`, `delete_customer_need`, `list_customers`, `save_customer`, `save_customer_need`
- `delete_status_update`, `get_status_updates`, `save_status_update`
- `get_diff`, `get_diff_threads`, `list_diffs`
- `extract_images`
- `get_document`, `list_documents`, `save_document`
- `get_issue`, `get_issue_status`, `list_issue_statuses`, `list_issues`, `save_issue`
- `get_initiative`, `list_initiatives`, `save_initiative`
- `get_milestone`, `list_milestones`, `save_milestone`
- `get_project`, `list_projects`, `save_project`
- `get_team`, `list_teams`
- `get_user`, `list_users`
- `list_cycles`
- `search_documentation`

Note: diff tools are bridged through Linear's MCP endpoint because the public GraphQL schema does not expose diff/review objects for personal API-key access. If Linear MCP returns `invalid_request`, the CLI returns a structured `unsupported` response with the MCP error.

There is also an escape hatch for unsupported/new Linear GraphQL operations:

```bash
~/.pi/agent/skills/linear/scripts/linear.js query '{"query":"query { viewer { id name email } }"}'
```

## Argument conventions

- Resources can usually be referenced by UUID, display name, key, or issue identifier (`CP-299`).
- `save_*` creates when `id` is omitted and updates when `id` is present.
- Common aliases are accepted, e.g. `issue`/`issueId`, `body`/`comment`, `state`/`status`, `team`/`teamId`.
- Output is JSON.

See `references/tools.md` for details and examples.
