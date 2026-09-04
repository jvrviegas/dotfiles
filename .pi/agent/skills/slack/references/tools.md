# Slack CLI tool reference

All commands use:

```bash
~/.pi/agent/skills/slack/scripts/slack.js TOOL '{"json":"args"}'
```

## Channels

```bash
# List all public channels
slack.js slack_list_channels '{"limit":100}'

# List with specific types (public_channel, private_channel, mpim, im)
slack.js slack_list_channels '{"types":"public_channel,private_channel","limit":50}'

# Create a channel
slack.js slack_create_conversation '{"name":"new-project","is_private":false}'

# Create a private channel
slack.js slack_create_conversation '{"name":"secret-project","is_private":true}'

# List channel members
slack.js slack_list_channel_members '{"channel":"general"}'
slack.js slack_list_channel_members '{"channel":"C123ABC"}'
```

## Messages

```bash
# Post a plain text message
slack.js slack_post_message '{"channel":"general","text":"Hello world!"}'

# Post a message with markdown
slack.js slack_post_message '{"channel":"general","text":"*Bold* and _italic_","mrkdwn":true}'

# Post to a thread
slack.js slack_post_message '{"channel":"general","text":"Threaded reply","thread_ts":"1234567890.123456"}'

# Reply to a thread (dedicated tool)
slack.js slack_reply_to_thread '{"channel":"C123","thread_ts":"1234567890.123456","text":"My reply"}'

# Post with Block Kit blocks
slack.js slack_post_message '{"channel":"general","blocks":[{"type":"section","text":{"type":"mrkdwn","text":"*Hello*"}}]}'

# Control link unfurling
slack.js slack_post_message '{"channel":"general","text":"Check https://example.com","unfurl_links":false,"unfurl_media":false}'
```

## Channel history and threads

```bash
# Get recent messages from a channel
slack.js slack_get_channel_history '{"channel":"general","limit":20}'

# Get messages in a time range (Unix timestamps)
slack.js slack_get_channel_history '{"channel":"general","oldest":"1700000000","latest":"1700086400"}'

# Include the latest message
slack.js slack_get_channel_history '{"channel":"general","inclusive":true}'

# Paginate with cursor
slack.js slack_get_channel_history '{"channel":"general","cursor":"dXNlcjpVMEc="}'

# Get all replies in a thread
slack.js slack_get_thread_replies '{"channel":"C123","thread_ts":"1234567890.123456"}'
```

## Reactions

```bash
# Add a reaction emoji to a message
slack.js slack_add_reaction '{"channel":"C123","timestamp":"1234567890.123456","name":"thumbsup"}'
slack.js slack_add_reaction '{"channel":"general","timestamp":"1234567890.123456","name":"tada"}'
```

## Users

```bash
# List all users in the workspace
slack.js slack_get_users '{"limit":200}'

# Get detailed profile for a user (by ID, name, or email)
slack.js slack_get_user_profile '{"user":"U123ABC"}'
slack.js slack_get_user_profile '{"user":"joao"}'
slack.js slack_get_user_profile '{"user":"joao@example.com"}'
```

## Search

```bash
# Search messages
slack.js slack_search_messages '{"query":"project proposal"}'

# Search with filters
slack.js slack_search_messages '{"query":"from:@joao project proposal","limit":20}'
slack.js slack_search_messages '{"query":"has:link in:general","sort":"timestamp","sort_dir":"desc"}'
slack.js slack_search_messages '{"query":"before:2026-01-01 after:2025-12-01"}'
```

## Files

```bash
# Get file metadata and download URL
slack.js slack_get_file '{"file":"F123ABC"}'
```

## Auth

```bash
# Verify token and get bot identity
slack.js auth_test
```

## Argument Conventions

- **channel**: Accepts channel ID (`C123ABC`) or name (`general`). Names are resolved via `conversations.list` with caching.
- **user**: Accepts user ID (`U123ABC`), username, real name, or email. Resolved via `users.list` with caching.
- **timestamp / thread_ts**: Slack ts format (`1234567890.123456`).
- **cursor**: For pagination, use the `next_cursor` from `response_metadata`.
- **limit**: Maximum items to return (varies by method, typically 100 default).
