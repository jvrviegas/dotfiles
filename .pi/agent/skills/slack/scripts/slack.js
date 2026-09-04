#!/usr/bin/env node
/* Slack MCP-style CLI for pi skills. Requires SLACK_BOT_TOKEN. */
const { execFileSync } = require('node:child_process');

const API = 'https://slack.com/api';

function getToken() {
  if (process.env.SLACK_BOT_TOKEN) return process.env.SLACK_BOT_TOKEN;
  if (process.platform === 'darwin') {
    try {
      return execFileSync('security', ['find-generic-password', '-s', 'pi Slack Skill', '-a', 'SLACK_BOT_TOKEN', '-w'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    } catch {}
  }
  return undefined;
}

const token = getToken();
const tool = process.argv[2];
const raw = process.argv.slice(3).join(' ').trim();
let args = {};
try { args = raw ? JSON.parse(raw) : {}; } catch (e) { die(`Invalid JSON arguments: ${e.message}`); }

function die(msg, code = 1) { console.error(JSON.stringify({ error: msg }, null, 2)); process.exit(code); }
function out(x) { console.log(JSON.stringify(x, null, 2)); }

async function slack(method, params = {}) {
  if (!token) die('Set SLACK_BOT_TOKEN or store it in macOS Keychain. See SKILL.md setup instructions.');
  const url = new URL(`${API}/${method}`);
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null) url.searchParams.set(k, Array.isArray(v) ? v.join(',') : String(v));
  }
  const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded', authorization: `Bearer ${token}` } });
  const json = await res.json();
  if (!json.ok) die(json.error || `Slack API error: ${res.status}`);
  return json;
}

const channelCache = new Map();
const userCache = new Map();

async function resolveChannel(value) {
  if (!value) return undefined;
  if (/^[CDGU][A-Z0-9]{8,}$/.test(value)) return value;
  if (channelCache.has(value.toLowerCase())) return channelCache.get(value.toLowerCase());
  let cursor;
  do {
    const res = await slack('conversations.list', { types: 'public_channel,private_channel,mpim,im', limit: 200, cursor });
    for (const ch of res.channels || []) {
      channelCache.set(ch.id.toLowerCase(), ch.id);
      channelCache.set(ch.name?.toLowerCase(), ch.id);
    }
    cursor = res.response_metadata?.next_cursor;
  } while (cursor);
  const id = channelCache.get(value.toLowerCase());
  if (!id) die(`Could not resolve channel: ${value}`);
  return id;
}

async function resolveUser(value) {
  if (!value) return undefined;
  if (/^[UW][A-Z0-9]{8,}$/.test(value)) return value;
  if (userCache.has(value.toLowerCase())) return userCache.get(value.toLowerCase());
  let cursor;
  do {
    const res = await slack('users.list', { limit: 200, cursor });
    for (const u of res.members || []) {
      userCache.set(u.id.toLowerCase(), u.id);
      if (u.name) userCache.set(u.name.toLowerCase(), u.id);
      if (u.profile?.email) userCache.set(u.profile.email.toLowerCase(), u.id);
      if (u.real_name) userCache.set(u.real_name.toLowerCase(), u.id);
    }
    cursor = res.response_metadata?.next_cursor;
  } while (cursor);
  const id = userCache.get(value.toLowerCase());
  if (!id) die(`Could not resolve user: ${value}`);
  return id;
}

async function collectPages(method, params, key, max = 500) {
  const items = [];
  let cursor;
  do {
    const res = await slack(method, { ...params, limit: Math.min(params.limit || 100, max - items.length), cursor });
    items.push(...(res[key] || []));
    cursor = res.response_metadata?.next_cursor;
    if (items.length >= max) break;
  } while (cursor);
  return items;
}

async function main() {
  switch (tool) {
    case 'auth_test':
      return out(await slack('auth.test'));

    case 'slack_list_channels': {
      const channels = await collectPages('conversations.list',
        { types: args.types || 'public_channel', limit: args.limit || 100 },
        'channels', args.limit || 500);
      return out({ channels, response_metadata: { total: channels.length } });
    }

    case 'slack_post_message': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const params = { channel, text: args.text };
      if (args.thread_ts) params.thread_ts = args.thread_ts;
      if (args.blocks) params.blocks = typeof args.blocks === 'string' ? args.blocks : JSON.stringify(args.blocks);
      if (args.mrkdwn !== undefined) params.mrkdwn = args.mrkdwn;
      if (args.unfurl_links !== undefined) params.unfurl_links = args.unfurl_links;
      if (args.unfurl_media !== undefined) params.unfurl_media = args.unfurl_media;
      return out(await slack('chat.postMessage', params));
    }

    case 'slack_reply_to_thread': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const threadTs = args.thread_ts || args.ts;
      if (!threadTs) die('slack_reply_to_thread requires thread_ts');
      const params = { channel, thread_ts: threadTs, text: args.text };
      if (args.blocks) params.blocks = typeof args.blocks === 'string' ? args.blocks : JSON.stringify(args.blocks);
      if (args.mrkdwn !== undefined) params.mrkdwn = args.mrkdwn;
      return out(await slack('chat.postMessage', params));
    }

    case 'slack_add_reaction': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const timestamp = args.timestamp || args.ts;
      if (!timestamp) die('slack_add_reaction requires timestamp');
      return out(await slack('reactions.add', { channel, name: args.name, timestamp }));
    }

    case 'slack_get_channel_history': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const params = { channel, limit: args.limit || 100 };
      if (args.latest) params.latest = args.latest;
      if (args.oldest) params.oldest = args.oldest;
      if (args.inclusive !== undefined) params.inclusive = args.inclusive;
      if (args.cursor) params.cursor = args.cursor;
      return out(await slack('conversations.history', params));
    }

    case 'slack_get_thread_replies': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const threadTs = args.thread_ts || args.ts;
      if (!threadTs) die('slack_get_thread_replies requires thread_ts');
      return out(await slack('conversations.replies', { channel, ts: threadTs, limit: args.limit || 100 }));
    }

    case 'slack_get_users': {
      const users = await collectPages('users.list',
        { limit: args.limit || 200 },
        'members', args.limit || 1000);
      return out({ members: users, response_metadata: { total: users.length } });
    }

    case 'slack_get_user_profile': {
      const user = await resolveUser(args.user || args.user_id);
      return out(await slack('users.info', { user }));
    }

    case 'slack_search_messages': {
      if (!args.query) die('slack_search_messages requires query');
      const params = { query: args.query, limit: args.limit || 20 };
      if (args.sort) params.sort = args.sort;
      if (args.sort_dir) params.sort_dir = args.sort_dir;
      if (args.cursor) params.cursor = args.cursor;
      return out(await slack('search.messages', params));
    }

    case 'slack_create_conversation': {
      const params = { name: args.name };
      if (args.is_private !== undefined) params.is_private = args.is_private;
      if (args.user_ids) params.user_ids = Array.isArray(args.user_ids) ? args.user_ids.join(',') : args.user_ids;
      return out(await slack('conversations.create', params));
    }

    case 'slack_list_channel_members': {
      const channel = await resolveChannel(args.channel || args.channel_id);
      const members = await collectPages('conversations.members',
        { channel, limit: args.limit || 100 },
        'members', args.limit || 1000);
      return out({ members, response_metadata: { total: members.length } });
    }

    case 'slack_get_file': {
      const fileId = args.file || args.file_id;
      if (!fileId) die('slack_get_file requires file');
      return out(await slack('files.info', { file: fileId }));
    }

    default:
      die(`Unknown tool: ${tool}. See SKILL.md for supported Slack MCP-style tools.`);
  }
}

main().catch(e => die(e.stack || e.message));
