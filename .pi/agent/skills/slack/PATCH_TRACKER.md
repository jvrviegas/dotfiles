# Slack skill patch tracker

Last created: 2026-06-26

This document tracks the work needed to bring `~/.pi/agent/skills/slack` in sync with Slack's official MCP server.

## Sources of truth

- Local skill files:
  - `SKILL.md`
  - `references/tools.md`
  - `scripts/slack.js`
- Official Slack MCP server: `https://mcp.slack.com/mcp`
  - The official MCP server uses confidential OAuth (not bot tokens) and exposes a broader tool set.
- Slack Web API: `https://api.slack.com/methods`

## Current state

The skill uses the Slack Web API with a bot token (`xoxb-...`). This is a simpler auth model than the official MCP's confidential OAuth, but provides the same core functionality.

### Implemented tools (12)

- `auth_test` (local extra)
- `slack_list_channels`
- `slack_post_message`
- `slack_reply_to_thread`
- `slack_add_reaction`
- `slack_get_channel_history`
- `slack_get_thread_replies`
- `slack_get_users`
- `slack_get_user_profile`
- `slack_search_messages`
- `slack_create_conversation`
- `slack_list_channel_members`
- `slack_get_file`

### Tools from official MCP not yet implemented

Based on the official Slack MCP documentation and the May 2026 changelog:

- [ ] `slack_list_emoji` — list custom emoji in the workspace (`emoji.list`)
- [ ] `slack_create_canvas` — create a Slack canvas (`canvases.create`)
- [ ] `slack_update_canvas` — update a canvas (`canvases.update`)
- [ ] `slack_read_canvas` — read a canvas as markdown (`canvases.read`)
- [ ] `slack_delete_message` — delete a message (`chat.delete`)
- [ ] `slack_update_message` — update a message (`chat.update`)
- [ ] `slack_get_channel_info` — get channel details (`conversations.info`)

## Patch tasks

| ID | Priority | Status | Area | Change needed | Acceptance check |
| --- | --- | --- | --- | --- | --- |
| SLK-001 | P1 | [ ] | Emoji | Add `slack_list_emoji` using `emoji.list` API | Returns custom emoji list |
| SLK-002 | P1 | [ ] | Canvas | Add `slack_create_canvas`, `slack_update_canvas`, `slack_read_canvas` using canvas APIs | Can create, update, and read canvases |
| SLK-003 | P2 | [ ] | Messages | Add `slack_delete_message` and `slack_update_message` | Can delete and edit messages |
| SLK-004 | P2 | [ ] | Channels | Add `slack_get_channel_info` using `conversations.info` | Returns channel details |
| SLK-005 | P2 | [ ] | Rate limits | Add rate limit handling with retry-after | Does not crash on 429 responses |
| SLK-006 | P2 | [ ] | Pagination | Add cursor-based pagination to `slack_list_channels` | Full channel list retrievable with cursor |

## Verification checklist

```bash
CLI="$HOME/.pi/agent/skills/slack/scripts/slack.js"
node --check $CLI
$CLI auth_test
$CLI slack_list_channels '{"limit":5}'
$CLI slack_get_users '{"limit":5}'
$CLI slack_search_messages '{"query":"test","limit":1}'
```
