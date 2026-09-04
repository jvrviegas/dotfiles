---
name: sentry
description: "Communicate with Sentry from pi using a local CLI for the Procimo organization (procimo-tech-a7). Use for Sentry issue/error triage, projects, events, releases, stats, and updating issue state."
compatibility: "Requires Node.js 18+ and a Sentry auth token in SENTRY_AUTH_TOKEN/SENTRY_TOKEN or macOS Keychain. Organization defaults to procimo-tech-a7."
---

# Sentry

Use this skill whenever the user asks to read or update Sentry data, investigate production errors, inspect events, list projects/releases, or resolve/ignore Sentry issues.

Pi does not provide Sentry MCP tools directly, so this skill exposes a local CLI. The CLI uses Sentry's REST API and is preconfigured for the Procimo organization slug:

```text
procimo-tech-a7
```

## Setup

1. Create a Sentry auth token with the scopes needed for your task. Common scopes:
   - Read-only triage: `org:read`, `project:read`, `event:read`
   - Updating issues: add `event:write`
   - Releases/deploys: `project:releases`
2. Store it securely. Recommended on macOS, use Keychain:

```bash
read -s SENTRY_AUTH_TOKEN
security add-generic-password -a SENTRY_AUTH_TOKEN -s "pi Sentry Skill" -w "$SENTRY_AUTH_TOKEN" -U
unset SENTRY_AUTH_TOKEN
```

Alternative: export it in your shell:

```bash
export SENTRY_AUTH_TOKEN="sntrys_..."
# SENTRY_TOKEN is also accepted
```

Check auth:

```bash
~/.pi/agent/skills/sentry/scripts/sentry.js authenticate
```

## Usage

Run a tool by name:

```bash
~/.pi/agent/skills/sentry/scripts/sentry.js <tool-name> '<json-arguments>'
```

Examples:

```bash
# List projects in the prefilled Procimo org
~/.pi/agent/skills/sentry/scripts/sentry.js list_projects

# List unresolved issues for a project
~/.pi/agent/skills/sentry/scripts/sentry.js list_issues '{"project":"dms-backend","query":"is:unresolved","limit":10}'

# Get an issue/group by numeric Sentry issue ID
~/.pi/agent/skills/sentry/scripts/sentry.js get_issue '{"id":"1234567890"}'

# List latest events for an issue
~/.pi/agent/skills/sentry/scripts/sentry.js list_issue_events '{"issue":"1234567890","limit":5}'

# Get a project event
~/.pi/agent/skills/sentry/scripts/sentry.js get_event '{"project":"dms-backend","event":"abcdef123"}'

# Resolve an issue
~/.pi/agent/skills/sentry/scripts/sentry.js update_issue '{"id":"1234567890","status":"resolved"}'

# Escape hatch for unsupported Sentry API calls
~/.pi/agent/skills/sentry/scripts/sentry.js request '{"method":"GET","path":"/organizations/procimo-tech-a7/issues/","query":{"query":"is:unresolved"}}'
```

## Tools

- `authenticate`
- `list_projects`, `get_project`
- `list_issues`, `get_issue`, `update_issue`
- `list_issue_events`, `get_issue_event`
- `list_project_events`, `get_event`
- `list_releases`, `get_release`
- `list_organization_members`
- `organization_stats`
- `request` (escape hatch for any Sentry REST API endpoint)

Output is JSON. See `references/tools.md` for argument details and examples.
