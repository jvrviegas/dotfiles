#!/usr/bin/env node
/* Sentry CLI for pi skills. Requires SENTRY_AUTH_TOKEN or SENTRY_TOKEN. */
const { execFileSync } = require('node:child_process');

const API = 'https://sentry.io/api/0';
const ORG = 'procimo-tech-a7';

function getToken() {
  if (process.env.SENTRY_AUTH_TOKEN || process.env.SENTRY_TOKEN) return process.env.SENTRY_AUTH_TOKEN || process.env.SENTRY_TOKEN;
  if (process.platform === 'darwin') {
    try {
      return execFileSync('security', ['find-generic-password', '-s', 'pi Sentry Skill', '-a', 'SENTRY_AUTH_TOKEN', '-w'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
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
function compact(o) { return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined && v !== null && v !== '')); }
function enc(x) { return encodeURIComponent(String(x)); }
function requireArg(value, name) { if (value === undefined || value === null || value === '') die(`Missing required argument: ${name}`); return value; }
function limit(n, fallback = 50) { return Math.max(1, Math.min(Number(n || fallback), 100)); }

function url(path, query = {}) {
  const u = new URL(path.startsWith('http') ? path : `${API}${path.startsWith('/') ? '' : '/'}${path}`);
  for (const [k, v] of Object.entries(compact(query))) {
    if (Array.isArray(v)) v.forEach(item => u.searchParams.append(k, item));
    else u.searchParams.set(k, String(v));
  }
  return u;
}

function parseLinks(linkHeader) {
  if (!linkHeader) return undefined;
  return Object.fromEntries(linkHeader.split(',').map(part => {
    const cursor = part.match(/cursor="([^"]+)"/)?.[1];
    const rel = part.match(/rel="([^"]+)"/)?.[1];
    const results = part.match(/results="([^"]+)"/)?.[1];
    return rel ? [rel, compact({ cursor, results })] : undefined;
  }).filter(Boolean));
}

async function request(method, path, { query, body, throwOnError } = {}) {
  if (!token) die('Set SENTRY_AUTH_TOKEN/SENTRY_TOKEN or store it in macOS Keychain: security add-generic-password -a SENTRY_AUTH_TOKEN -s "pi Sentry Skill" -w "sntrys_..." -U');
  const res = await fetch(url(path, query), {
    method,
    headers: compact({
      authorization: `Bearer ${token}`,
      'content-type': body === undefined ? undefined : 'application/json',
      accept: 'application/json'
    }),
    body: body === undefined ? undefined : JSON.stringify(body)
  });
  const text = await res.text();
  let data;
  try { data = text ? JSON.parse(text) : {}; } catch { data = text; }
  if (!res.ok) {
    const detail = typeof data === 'object' ? (data.detail || data.error || data.message || JSON.stringify(data)) : data;
    const message = `${res.status} ${res.statusText}${detail ? `: ${detail}` : ''}`;
    if (throwOnError) throw new Error(message);
    die(message);
  }
  const links = parseLinks(res.headers.get('link'));
  return links ? { data, page: links } : data;
}

async function resolveProjectId(project) {
  if (!project) return undefined;
  const value = String(project);
  if (/^\d+$/.test(value)) return value;
  const projectData = await request('GET', `/projects/${enc(ORG)}/${enc(value)}/`);
  return projectData.id;
}

async function main() {
  switch (tool) {
    case 'authenticate': {
      const user = await request('GET', '/auth/');
      try {
        const org = await request('GET', `/organizations/${enc(ORG)}/`, { throwOnError: true });
        return out({ ok: true, organizationSlug: ORG, user, organization: org });
      } catch (e) {
        return out({ ok: false, organizationSlug: ORG, user, organizationError: String(e.message || e), hint: 'Token is valid, but cannot read the prefilled organization. Add org:read (and project:read/event:read as needed) or verify access to procimo-tech-a7.' });
      }
    }
    case 'list_projects':
      return out(await request('GET', `/organizations/${enc(ORG)}/projects/`, { query: { per_page: limit(args.limit, 100), cursor: args.cursor } }));
    case 'get_project': {
      const project = requireArg(args.project || args.slug || args.id, 'project');
      return out(await request('GET', `/projects/${enc(ORG)}/${enc(project)}/`));
    }
    case 'list_issues': {
      const projectId = await resolveProjectId(args.project || args.projectId);
      return out(await request('GET', `/organizations/${enc(ORG)}/issues/`, { query: compact({ project: projectId, query: args.query, statsPeriod: args.statsPeriod, sort: args.sort, per_page: limit(args.limit), cursor: args.cursor }) }));
    }
    case 'get_issue': {
      const id = requireArg(args.id || args.issue, 'id');
      return out(await request('GET', `/issues/${enc(id)}/`));
    }
    case 'update_issue': {
      const id = requireArg(args.id || args.issue, 'id');
      const body = compact({ status: args.status, statusDetails: args.statusDetails, assignedTo: args.assignedTo, isBookmarked: args.isBookmarked, hasSeen: args.hasSeen });
      if (!Object.keys(body).length) die('Provide at least one field to update: status, statusDetails, assignedTo, isBookmarked, hasSeen');
      return out(await request('PUT', `/issues/${enc(id)}/`, { body }));
    }
    case 'list_issue_events': {
      const id = requireArg(args.issue || args.id, 'issue');
      return out(await request('GET', `/issues/${enc(id)}/events/`, { query: { per_page: limit(args.limit, 50), cursor: args.cursor } }));
    }
    case 'get_issue_event': {
      const id = requireArg(args.issue || args.id, 'issue');
      const event = requireArg(args.event || args.eventId, 'event');
      return out(await request('GET', `/issues/${enc(id)}/events/${enc(event)}/`));
    }
    case 'list_project_events': {
      const project = requireArg(args.project || args.slug, 'project');
      return out(await request('GET', `/projects/${enc(ORG)}/${enc(project)}/events/`, { query: compact({ query: args.query, statsPeriod: args.statsPeriod, full: args.full, per_page: limit(args.limit), cursor: args.cursor }) }));
    }
    case 'get_event': {
      const project = requireArg(args.project || args.slug, 'project');
      const event = requireArg(args.event || args.eventId, 'event');
      return out(await request('GET', `/projects/${enc(ORG)}/${enc(project)}/events/${enc(event)}/`));
    }
    case 'list_releases': {
      const project = args.project || args.slug;
      return out(await request('GET', `/organizations/${enc(ORG)}/releases/`, { query: compact({ project, query: args.query, per_page: limit(args.limit), cursor: args.cursor }) }));
    }
    case 'get_release': {
      const version = requireArg(args.version || args.release, 'version');
      return out(await request('GET', `/organizations/${enc(ORG)}/releases/${enc(version)}/`));
    }
    case 'list_organization_members':
      return out(await request('GET', `/organizations/${enc(ORG)}/members/`, { query: { per_page: limit(args.limit, 100), cursor: args.cursor } }));
    case 'organization_stats':
      return out(await request('GET', `/organizations/${enc(ORG)}/stats/`, { query: compact({ stat: args.stat || 'received', since: args.since, until: args.until, resolution: args.resolution }) }));
    case 'request': {
      const method = String(args.method || 'GET').toUpperCase();
      const path = requireArg(args.path, 'path');
      return out(await request(method, path, { query: args.query, body: args.body }));
    }
    default:
      die(`Unknown tool: ${tool || '(none)'}\nAvailable tools: authenticate, list_projects, get_project, list_issues, get_issue, update_issue, list_issue_events, get_issue_event, list_project_events, get_event, list_releases, get_release, list_organization_members, organization_stats, request`);
  }
}

main().catch(e => die(e.stack || e.message || String(e)));
