---
name: slack
description: "Communicate with Slack from pi using a CLI with Slack MCP-style tools: list channels, post messages, reply in threads, add reactions, read channel/thread history, search messages, list users, get profiles, create conversations, list members, and manage files. Use for Slack messaging, searching workspace history, and channel management."
compatibility: "Requires Node.js 18+ and a Slack bot token (xoxb-...) in SLACK_BOT_TOKEN or macOS Keychain."
---

# Slack

Use this skill whenever the user asks to read, post, or search Slack data.

Pi does not provide MCP tools directly, so this skill exposes a local CLI with Slack MCP-style tool names. The CLI uses Slack's Web API. Remaining parity gaps are tracked in `PATCH_TRACKER.md`.

## Setup

1. Create a Slack app at https://api.slack.com/apps and install it to your workspace.
2. Give the bot the necessary OAuth scopes (see Scope Reference below).
3. Copy the Bot User OAuth Token (starts with `xoxb-`).
4. Invite the bot to any channels you want it to access.
5. Store the token securely. Recommended on macOS, use Keychain:

```bash
read -s SLACK_BOT_TOKEN
security add-generic-password -a SLACK_BOT_TOKEN -s "pi Slack Skill" -w "$SLACK_BOT_TOKEN" -U
unset SLACK_BOT_TOKEN
```

Alternative: export it in your shell:

```bash
export SLACK_BOT_TOKEN="xoxb-..."
```

Check auth:

```bash
~/.pi/agent/skills/slack/scripts/slack.js auth_test
```

## Scope Reference

| Tools | Required Scopes |
| --- | --- |
| list_channels, list_channel_members | `channels:read`, `groups:read`, `mpim:read`, `im:read` |
| post_message, reply_to_thread | `chat:write` |
| get_channel_history, get_thread_replies | `channels:history`, `groups:history`, `mpim:history`, `im:history` |
| add_reaction | `reactions:write` |
| get_users, get_user_profile | `users:read`, `users:read.email` |
| search_messages | `search:read` |
| get_file | `files:read` |
| create_conversation | `channels:write`, `groups:write`, `im:write`, `mpim:write` |

## Usage

Run any implemented Slack MCP-style tool by name:

```bash
~/.pi/agent/skills/slack/scripts/slack.js <tool-name> '<json-arguments>'
```

Examples:

```bash
# List channels
~/.pi/agent/skills/slack/scripts/slack.js slack_list_channels '{"limit":50}'

# Post a message
~/.pi/agent/skills/slack/scripts/slack.js slack_post_message '{"channel":"general","text":"Hello from pi!"}'

# Reply in a thread
~/.pi/agent/skills/slack/scripts/slack.js slack_reply_to_thread '{"channel":"C123","thread_ts":"1234567890.123456","text":"My reply"}'

# Add a reaction
~/.pi/agent/skills/slack/scripts/slack.js slack_add_reaction '{"channel":"C123","timestamp":"1234567890.123456","name":"thumbsup"}'

# Get channel history
~/.pi/agent/skills/slack/scripts/slack.js slack_get_channel_history '{"channel":"C123","limit":20}'

# Get thread replies
~/.pi/agent/skills/slack/scripts/slack.js slack_get_thread_replies '{"channel":"C123","thread_ts":"1234567890.123456"}'

# Search messages
~/.pi/agent/skills/slack/scripts/slack.js slack_search_messages '{"query":"from:@joao project proposal","limit":20}'

# List users
~/.pi/agent/skills/slack/scripts/slack.js slack_get_users '{"limit":100}'

# Get user profile
~/.pi/agent/skills/slack/scripts/slack.js slack_get_user_profile '{"user":"U123"}'

# Create a conversation
~/.pi/agent/skills/slack/scripts/slack.js slack_create_conversation '{"name":"new-project","is_private":false}'

# List channel members
~/.pi/agent/skills/slack/scripts/slack.js slack_list_channel_members '{"channel":"C123"}'

# Get file info
~/.pi/agent/skills/slack/scripts/slack.js slack_get_file '{"file":"F123"}'
```

## Implemented MCP-style tools

The CLI implements these Slack MCP-style tool names:

- `auth_test` — verify authentication
- `slack_list_channels` — list public channels with pagination
- `slack_post_message` — post a new message to a channel
- `slack_reply_to_thread` — reply to a specific message thread
- `slack_add_reaction` — add an emoji reaction to a message
- `slack_get_channel_history` — get recent messages from a channel
- `slack_get_thread_replies` — get all replies in a message thread
- `slack_get_users` — list all users in the workspace
- `slack_get_user_profile` — get detailed profile for a specific user
- `slack_search_messages` — search messages and files in the workspace
- `slack_create_conversation` — create a new channel, group DM, or IM
- `slack_list_channel_members` — list members of a channel
- `slack_get_file` — get file metadata and download URL

Note: Canvas and emoji tools are not yet implemented and are tracked in `PATCH_TRACKER.md`.

## Argument conventions

- `channel` can be a channel ID (e.g., `C123`) or channel name (e.g., `general`). Names are resolved to IDs automatically.
- `user` can be a user ID (e.g., `U123`) or username/email. Names are resolved to IDs automatically.
- `timestamp` / `thread_ts` use Slack's ts format (e.g., `1234567890.123456`).
- Output is JSON.

See `references/tools.md` for details and examples.
