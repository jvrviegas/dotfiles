#!/usr/bin/env node
/* Linear MCP-style CLI for pi skills. Requires LINEAR_API_KEY or LINEAR_TOKEN. */
const { execFileSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const { basename } = require('node:path');
const API = 'https://api.linear.app/graphql';
const MCP_API = 'https://mcp.linear.app/mcp';
function getToken() {
  if (process.env.LINEAR_API_KEY || process.env.LINEAR_TOKEN) return process.env.LINEAR_API_KEY || process.env.LINEAR_TOKEN;
  if (process.platform === 'darwin') {
    try {
      return execFileSync('security', ['find-generic-password', '-s', 'pi Linear Skill', '-a', 'LINEAR_API_KEY', '-w'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
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
function compact(o) { return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined && v !== null)); }
function compactUndefined(o) { return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined)); }
function asArray(v) { return v === undefined || v === null ? undefined : (Array.isArray(v) ? v : [v]); }
function argValue(...names) { for (const name of names) if (Object.prototype.hasOwnProperty.call(args, name)) return args[name]; return undefined; }
async function gql(query, variables = {}) {
  if (!token && tool !== 'search_documentation' && tool !== 'extract_images') die('Set LINEAR_API_KEY/LINEAR_TOKEN or store it in macOS Keychain: security add-generic-password -a LINEAR_API_KEY -s "pi Linear Skill" -w "lin_api_..." -U');
  const res = await fetch(API, { method: 'POST', headers: { 'content-type': 'application/json', authorization: token }, body: JSON.stringify({ query, variables }) });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.errors) die(json.errors?.map(e => e.message).join('\n') || `${res.status} ${res.statusText}`);
  return json.data;
}
function parseMcpResponse(text) {
  const data = text.split(/\r?\n/).filter(line => line.startsWith('data:')).map(line => line.slice(5).trim()).join('\n') || text;
  return JSON.parse(data);
}
function parseMcpContent(result) {
  const text = result?.content?.find(item => item.type === 'text')?.text;
  if (!text) return result;
  try { return JSON.parse(text); } catch { return text; }
}
async function mcpCall(name, toolArgs) {
  if (!token) die('Set LINEAR_API_KEY/LINEAR_TOKEN or store it in macOS Keychain before using MCP-bridged tools.');
  const res = await fetch(MCP_API, { method: 'POST', headers: { 'content-type': 'application/json', accept: 'application/json, text/event-stream', authorization: `Bearer ${token}` }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name, arguments: toolArgs } }) });
  const text = await res.text();
  if (!res.ok) die(`${res.status} ${res.statusText}: ${text}`);
  const json = parseMcpResponse(text);
  if (json.error) die(json.error.message || JSON.stringify(json.error));
  return { raw: json.result, content: parseMcpContent(json.result) };
}
const page = `pageInfo{hasNextPage endCursor}`;
const issueFields = `id identifier title description priority estimate url branchName createdAt updatedAt dueDate team{id key name} state{id name type color} assignee{id name email} creator{id name email} project{id name url} cycle{id number name} parent{id identifier title} labels{nodes{id name color}} projectMilestone{id name targetDate}`;
const projectFields = `id name description slugId url status{id name type color} health targetDate startDate createdAt updatedAt teams{nodes{id key name}} lead{id name email}`;
const milestoneFields = `id name description targetDate createdAt updatedAt project{id name url}`;
const commentFields = `id body createdAt updatedAt url quotedText user{id name email} parent{id body} issue{id identifier title} project{id name} initiative{id name} documentContent{id document{id title} projectMilestone{id name}}`;
const userFields = `id name displayName email active admin avatarUrl createdAt updatedAt`;
const teamFields = `id key name description icon visibility createdAt updatedAt`;
const stateFields = `id name type color position team{id key name}`;
const labelFields = `id name description color createdAt updatedAt team{id key name}`;
const projectLabelFields = `id name description color createdAt updatedAt`;
const projectStatusFields = `id name type color position createdAt updatedAt`;
const customerFields = `id name domains externalIds url slugId revenue size logoUrl createdAt updatedAt owner{id name email} status{id name displayName color} tier{id name displayName color}`;
const customerStatusFields = `id name displayName color createdAt updatedAt`;
const customerTierFields = `id name displayName color createdAt updatedAt`;
const initiativeFields = `id name description content slugId url status health color icon targetDate targetDateResolution createdAt updatedAt owner{id name email} leadTeam{id key name}`;
const documentFields = `id title content url icon color createdAt updatedAt project{id name} issue{id identifier title} initiative{id name} cycle{id number name} team{id key name} creator{id name email}`;
const uploadFileFields = `filename contentType size uploadUrl assetUrl headers{key value} metaData`;

async function conn(root, field, vars, fields) {
  const data = await gql(`query($first:Int,$after:String,$filter:${root}Filter){ ${field}(first:$first, after:$after, filter:$filter){ nodes{${fields}} ${page} } }`, vars);
  return data[field];
}
async function connPaged(root, field, vars, fields) {
  const data = await gql(`query($first:Int,$after:String,$filter:${root}Filter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ ${field}(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${fields}} ${page} } }`, vars);
  return data[field];
}
async function simpleConn(field, vars, fields) {
  const data = await gql(`query($first:Int,$after:String){ ${field}(first:$first, after:$after){ nodes{${fields}} ${page} } }`, vars);
  return data[field];
}
async function collectConn(root, field, vars, fields, max = 250) {
  const nodes = [];
  let after = vars.after;
  let pageInfo = { hasNextPage: true, endCursor: after };
  while (nodes.length < max && pageInfo.hasNextPage) {
    const first = Math.min(vars.first || 50, max - nodes.length);
    const result = await conn(root, field, { ...vars, first, after }, fields);
    nodes.push(...result.nodes);
    pageInfo = result.pageInfo || { hasNextPage: false };
    after = pageInfo.endCursor;
    if (!after) break;
  }
  return { nodes, pageInfo };
}
async function collectSimpleConn(field, vars, fields, max = 250) {
  const nodes = [];
  let after = vars.after;
  let pageInfo = { hasNextPage: true, endCursor: after };
  while (nodes.length < max && pageInfo.hasNextPage) {
    const first = Math.min(vars.first || 50, max - nodes.length);
    const result = await simpleConn(field, { ...vars, first, after }, fields);
    nodes.push(...result.nodes);
    pageInfo = result.pageInfo || { hasNextPage: false };
    after = pageInfo.endCursor;
    if (!after) break;
  }
  return { nodes, pageInfo };
}
async function resolve(kind, value, extra = {}) {
  if (!value) return undefined;
  if (/^[0-9a-f-]{20,}$/i.test(value)) return value;
  if (kind === 'issue') return (await getIssue(value)).id;
  if (kind === 'user' && String(value).toLowerCase() === 'me') return (await gql(`query{ viewer{id} }`)).viewer.id;
  const first = 50;
  const q = String(value).toLowerCase();
  if (kind === 'customerStatus' || kind === 'customerTier' || kind === 'projectStatus') {
    const simpleLists = {
      customerStatus: ['customerStatuses', customerStatusFields],
      customerTier: ['customerTiers', customerTierFields],
      projectStatus: ['projectStatuses', projectStatusFields]
    };
    const [field, fields] = simpleLists[kind];
    const nodes = (await collectSimpleConn(field, { first: 100 }, fields)).nodes;
    const hit = nodes.find(n => [n.id, n.name, n.displayName, n.type].filter(Boolean).some(v => String(v).toLowerCase() === q)) ||
                nodes.find(n => [n.name, n.displayName, n.type].filter(Boolean).some(v => String(v).toLowerCase().includes(q)));
    if (!hit) die(`Could not resolve ${kind}: ${value}`);
    return hit.id;
  }
  const lists = {
    team: ['Team', 'teams', teamFields], project: ['Project', 'projects', projectFields], user: ['User', 'users', userFields],
    state: ['WorkflowState', 'workflowStates', stateFields], label: ['IssueLabel', 'issueLabels', labelFields],
    projectLabel: ['ProjectLabel', 'projectLabels', projectLabelFields], projectStatus: ['ProjectStatus', 'projectStatuses', projectStatusFields],
    milestone: ['ProjectMilestone', 'projectMilestones', milestoneFields], cycle: ['Cycle', 'cycles', `id number name team{id key name}`],
    initiative: ['Initiative', 'initiatives', initiativeFields]
  };
  if (!lists[kind]) die(`Unknown resolver kind: ${kind}`);
  const [type, field, fields] = lists[kind];
  const filter = {};
  if ((kind === 'state' || kind === 'label' || kind === 'cycle') && extra.teamId) filter.team = { id: { eq: extra.teamId } };
  if (kind === 'project' && extra.teamId) filter.accessibleTeams = { some: { id: { eq: extra.teamId } } };
  if (kind === 'project') filter.or = [{ name: { containsIgnoreCase: String(value) } }, { slugId: { eqIgnoreCase: String(value) } }];
  if (kind === 'projectLabel' || kind === 'projectStatus') filter.name = { containsIgnoreCase: String(value) };
  if (kind === 'milestone') filter.name = { containsIgnoreCase: String(value) };
  if (kind === 'milestone' && extra.projectId) filter.project = { id: { eq: extra.projectId } };
  if (kind === 'initiative') filter.or = [{ name: { containsIgnoreCase: String(value) } }, { slugId: { eqIgnoreCase: String(value) } }];
  const nodes = (await collectConn(type, field, { first, filter }, fields, extra.max || 250)).nodes;
  const hit = nodes.find(n => [n.id, n.key, n.name, n.displayName, n.email, n.slugId, n.identifier, n.number == null ? undefined : String(n.number)].filter(Boolean).some(v => String(v).toLowerCase() === q)) ||
              nodes.find(n => [n.name, n.displayName, n.email].filter(Boolean).some(v => String(v).toLowerCase().includes(q)));
  if (!hit) die(`Could not resolve ${kind}: ${value}`);
  return hit.id;
}
async function getIssue(id) {
  const data = await gql(`query($id:String!){ issue(id:$id){ ${issueFields} comments(first:20){nodes{${commentFields}}} children(first:50){nodes{id identifier title state{id name}}} relations{nodes{id type relatedIssue{id identifier title}}} } }`, { id });
  return data.issue;
}
function comparator(value) {
  if (value === undefined || value === null) return undefined;
  return typeof value === 'object' && !Array.isArray(value) ? value : { eq: value };
}
async function filterArgs() {
  const teamId = await resolve('team', args.team || args.teamId);
  const projectId = await resolve('project', args.project || args.projectId, { teamId });
  const stateId = await resolve('state', args.state || args.status || args.stateId, { teamId });
  const assigneeId = await resolve('user', args.assignee || args.assigneeId);
  const delegateId = await resolve('user', args.delegate || args.delegateId);
  const milestoneId = await resolve('milestone', args.milestone || args.projectMilestone || args.milestoneId, { projectId });
  const parentId = await resolve('issue', args.parent || args.parentId);
  const labelArgs = asArray(args.labels !== undefined ? args.labels : args.label);
  const labelIds = labelArgs ? await Promise.all(labelArgs.map(l => resolve('label', l, { teamId }))) : undefined;
  const filter = {};
  if (teamId) filter.team = { id: { eq: teamId } };
  if (projectId) filter.project = { id: { eq: projectId } };
  if (stateId) filter.state = { id: { eq: stateId } };
  if (assigneeId) filter.assignee = { id: { eq: assigneeId } };
  if (delegateId) filter.delegate = { id: { eq: delegateId } };
  if (milestoneId) filter.projectMilestone = { id: { eq: milestoneId } };
  if (parentId) filter.parent = { id: { eq: parentId } };
  if (labelIds?.length) filter.labels = { some: { id: { in: labelIds } } };
  if (args.priority !== undefined) filter.priority = comparator(args.priority);
  if (args.createdAt) filter.createdAt = comparator(args.createdAt);
  if (args.updatedAt) filter.updatedAt = comparator(args.updatedAt);
  if (args.query || args.search) filter.or = [{ title: { containsIgnoreCase: args.query || args.search } }, { description: { containsIgnoreCase: args.query || args.search } }];
  return { filter, teamId, projectId };
}
async function listIssues() {
  const { filter } = await filterArgs();
  const data = await gql(`query($first:Int,$after:String,$filter:IssueFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ issues(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${issueFields}} ${page} } }`, { first: args.limit || 50, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.issues;
}
function afterComparator(value) {
  if (value === undefined || value === null) return undefined;
  return typeof value === 'object' && !Array.isArray(value) ? value : { gte: value };
}
function projectIncludeFields() {
  return `${args.includeMilestones ? ` projectMilestones(first:50){nodes{${milestoneFields}} ${page}}` : ''}${args.includeMembers ? ` members(first:50){nodes{id name email displayName} ${page}}` : ''}${args.includeResources ? ` documents(first:20){nodes{id title url createdAt updatedAt} ${page}} externalLinks(first:20){nodes{id url label createdAt updatedAt} ${page}} attachments(first:20){nodes{id title url createdAt updatedAt} ${page}}` : ''}`;
}
async function projectFilterArgs() {
  const teamId = await resolve('team', args.team || args.teamId);
  const statusId = await resolve('projectStatus', args.status || args.statusId || args.state);
  const initiativeId = await resolve('initiative', args.initiative || args.initiativeId);
  const memberId = await resolve('user', args.member || args.memberId);
  const labelId = await resolve('projectLabel', args.label || args.labelId);
  const filter = {};
  if (teamId) filter.accessibleTeams = { some: { id: { eq: teamId } } };
  if (statusId) filter.status = { id: { eq: statusId } };
  if (initiativeId) filter.initiatives = { some: { id: { eq: initiativeId } } };
  if (memberId) filter.members = { some: { id: { eq: memberId } } };
  if (labelId) filter.labels = { some: { id: { eq: labelId } } };
  if (args.createdAt) filter.createdAt = afterComparator(args.createdAt);
  if (args.updatedAt) filter.updatedAt = afterComparator(args.updatedAt);
  if (args.query || args.search) filter.or = [{ name: { containsIgnoreCase: args.query || args.search } }, { slugId: { containsIgnoreCase: args.query || args.search } }];
  return { filter, teamId };
}
async function listProjects() {
  const { filter } = await projectFilterArgs();
  const data = await gql(`query($first:Int,$after:String,$filter:ProjectFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ projects(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${projectFields}${projectIncludeFields()}} ${page} } }`, { first: args.limit || 50, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.projects;
}
async function getProject() {
  const teamId = await resolve('team', args.team || args.teamId);
  const data = await gql(`query($id:String!){ project(id:$id){${projectFields}${projectIncludeFields()} } }`, { id: await resolve('project', args.id || args.project || args.query, { teamId }) });
  return data.project;
}
async function documentFilterArgs() {
  const teamId = await resolve('team', args.team || args.teamId);
  const filter = {};
  const projectId = await resolve('project', args.project || args.projectId, { teamId });
  const issueId = await resolve('issue', args.issue || args.issueId);
  const initiativeId = await resolve('initiative', args.initiative || args.initiativeId);
  const cycleId = await resolve('cycle', args.cycle || args.cycleId, { teamId });
  const creatorId = await resolve('user', args.creator || args.creatorId);
  if (projectId) filter.project = { id: { eq: projectId } };
  if (issueId) filter.issue = { id: { eq: issueId } };
  if (initiativeId) filter.initiative = { id: { eq: initiativeId } };
  if (cycleId) filter.cycle = { id: { eq: cycleId } };
  if (teamId && !cycleId) filter.team = { id: { eq: teamId } };
  if (creatorId) filter.creator = { id: { eq: creatorId } };
  if (args.createdAt) filter.createdAt = afterComparator(args.createdAt);
  if (args.updatedAt) filter.updatedAt = afterComparator(args.updatedAt);
  if (args.query || args.search) filter.title = { containsIgnoreCase: args.query || args.search };
  return filter;
}
async function listDocuments() {
  const filter = await documentFilterArgs();
  const data = await gql(`query($first:Int,$after:String,$filter:DocumentFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ documents(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${documentFields}} ${page} } }`, { first: args.limit || 50, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.documents;
}
async function documentTargetInput() {
  const teamId = await resolve('team', args.team || args.teamId);
  const cycleId = await resolve('cycle', args.cycle || args.cycleId, { teamId });
  return compactUndefined({
    projectId: await resolve('project', args.project || args.projectId, { teamId }),
    issueId: await resolve('issue', args.issue || args.issueId),
    initiativeId: await resolve('initiative', args.initiative || args.initiativeId),
    cycleId,
    teamId: cycleId ? undefined : teamId
  });
}
async function listTeams() {
  const filter = {};
  if (args.query || args.search) filter.or = [{ name: { containsIgnoreCase: args.query || args.search } }, { key: { containsIgnoreCase: args.query || args.search } }];
  if (args.createdAt) filter.createdAt = afterComparator(args.createdAt);
  if (args.updatedAt) filter.updatedAt = afterComparator(args.updatedAt);
  const data = await gql(`query($first:Int,$after:String,$filter:TeamFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ teams(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${teamFields}} ${page} } }`, { first: args.limit || 100, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.teams;
}
async function listUsers() {
  const teamId = await resolve('team', args.team || args.teamId);
  const filter = args.query || args.search ? { or: [{ name: { containsIgnoreCase: args.query || args.search } }, { displayName: { containsIgnoreCase: args.query || args.search } }, { email: { containsIgnoreCase: args.query || args.search } }] } : undefined;
  if (teamId) {
    const data = await gql(`query($id:String!,$first:Int,$after:String,$filter:UserFilter,$includeDisabled:Boolean,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ team(id:$id){ members(first:$first, after:$after, filter:$filter, includeDisabled:$includeDisabled, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${userFields}} ${page} } } }`, { id: teamId, first: args.limit || 100, after: args.cursor || args.after, filter, includeDisabled: args.includeDisabled, includeArchived: args.includeArchived, orderBy: args.orderBy });
    return data.team.members;
  }
  const data = await gql(`query($first:Int,$after:String,$filter:UserFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ users(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${userFields}} ${page} } }`, { first: args.limit || 100, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.users;
}
async function listIssueStatuses() {
  const teamId = await resolve('team', args.team || args.teamId);
  const filter = {};
  if (teamId) filter.team = { id: { eq: teamId } };
  if (args.name || args.query) filter.name = { containsIgnoreCase: args.name || args.query };
  const data = await gql(`query($first:Int,$after:String,$filter:WorkflowStateFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ workflowStates(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${stateFields}} ${page} } }`, { first: args.limit || 100, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.workflowStates;
}
async function listIssueLabels() {
  const teamId = await resolve('team', args.team || args.teamId);
  const filter = {};
  if (teamId) filter.team = { id: { eq: teamId } };
  if (args.name || args.query) filter.name = { containsIgnoreCase: args.name || args.query };
  const data = await gql(`query($first:Int,$after:String,$filter:IssueLabelFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ issueLabels(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${labelFields}} ${page} } }`, { first: args.limit || 100, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.issueLabels;
}
async function listProjectLabels() {
  const filter = args.name || args.query ? { name: { containsIgnoreCase: args.name || args.query } } : undefined;
  const data = await gql(`query($first:Int,$after:String,$filter:ProjectLabelFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ projectLabels(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${projectLabelFields}} ${page} } }`, { first: args.limit || 100, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.projectLabels;
}
async function main() {
  switch (tool) {
    case 'authenticate': return out((await gql(`query{ viewer{${userFields}} organization{id name urlKey} }`)));
    case 'query': return out(await gql(args.query, args.variables || {}));
    case 'get_issue': return out(await getIssue(args.id || args.issue || args.identifier));
    case 'list_issues': return out(await listIssues());
    case 'list_teams': return out(await listTeams());
    case 'get_team': return out((await gql(`query($id:String!){ team(id:$id){${teamFields}} }`, { id: await resolve('team', args.id || args.team || args.query) })).team);
    case 'list_users': return out(await listUsers());
    case 'get_user': return out((await gql(`query($id:String!){ user(id:$id){${userFields}} }`, { id: await resolve('user', args.id || args.user || args.query) })).user);
    case 'list_projects': return out(await listProjects());
    case 'get_project': return out(await getProject());
    case 'list_milestones': { const projectId = await resolve('project', args.project || args.projectId); return out(await connPaged('ProjectMilestone', 'projectMilestones', { first: args.limit || 100, after: args.cursor || args.after, filter: projectId ? { project: { id: { eq: projectId } } } : undefined, includeArchived: args.includeArchived, orderBy: args.orderBy }, milestoneFields)); }
    case 'get_milestone': return out((await gql(`query($id:String!){ projectMilestone(id:$id){${milestoneFields}} }`, { id: await resolve('milestone', args.id || args.milestone) })).projectMilestone);
    case 'list_issue_statuses': return out(await listIssueStatuses());
    case 'get_issue_status': return out((await gql(`query($id:String!){ workflowState(id:$id){${stateFields}} }`, { id: await resolve('state', args.id || args.name || args.state || args.status, { teamId: await resolve('team', args.team || args.teamId) }) })).workflowState);
    case 'list_issue_labels': return out(await listIssueLabels());
    case 'list_project_labels': return out(await listProjectLabels());
    case 'list_cycles': { const teamId = await resolve('team', args.team || args.teamId); return out(await connPaged('Cycle', 'cycles', { first: args.limit || 50, after: args.cursor || args.after, filter: teamId ? { team: { id: { eq: teamId } } } : undefined, includeArchived: args.includeArchived, orderBy: args.orderBy }, `id number name startsAt endsAt completedAt team{id key name}`)); }
    case 'list_comments': return out(await listComments());
    case 'save_comment': return out(await saveComment());
    case 'delete_comment': return out(await gql(`mutation($id:String!){ commentDelete(id:$id){ success } }`, { id: args.id }));
    case 'save_issue': return out(await saveIssue());
    case 'save_project': return out(await saveProject());
    case 'save_milestone': return out(await saveMilestone());
    case 'list_initiatives': return out(await listInitiatives());
    case 'get_initiative': return out((await gql(`query($id:String!){ initiative(id:$id){${initiativeFields}} }`, { id: await resolve('initiative', args.id || args.initiative || args.query) })).initiative);
    case 'save_initiative': return out(await saveInitiative());
    case 'create_issue_label': return out(await gql(`mutation($input:IssueLabelCreateInput!){ issueLabelCreate(input:$input){ success issueLabel{${labelFields}} } }`, { input: compact({ name: args.name, description: args.description, color: args.color, teamId: await resolve('team', args.team || args.teamId) }) }));
    case 'list_documents': return out(await listDocuments());
    case 'get_document': return out((await gql(`query($id:String!){ document(id:$id){${documentFields}} }`, { id: args.id })).document);
    case 'save_document': return out(await saveDocument());
    case 'prepare_attachment_upload': return out(await prepareAttachmentUpload());
    case 'create_attachment_from_upload': return out(await createAttachmentFromUpload());
    case 'create_attachment': return out(await createAttachment());
    case 'get_attachment': return out((await gql(`query($id:String!){ attachment(id:$id){id title subtitle url metadata createdAt updatedAt issue{id identifier title}} }`, { id: args.id })).attachment);
    case 'delete_attachment': return out(await gql(`mutation($id:String!){ attachmentDelete(id:$id){ success } }`, { id: args.id }));
    case 'get_status_updates': return out(await listStatusUpdates());
    case 'save_status_update': return out(await saveStatusUpdate());
    case 'delete_status_update': return out(await gql(`mutation($id:String!){ projectUpdateArchive(id:$id){ success entity{id} } }`, { id: args.id }));
    case 'list_customers': return out(await connPaged('Customer', 'customers', { first: args.limit || 50, after: args.cursor || args.after, includeArchived: args.includeArchived, orderBy: args.orderBy }, customerFields));
    case 'save_customer': return out(await saveCustomer());
    case 'get_diff': return out(await diffTool('get_diff'));
    case 'list_diffs': return out(await diffTool('list_diffs'));
    case 'get_diff_threads': return out(await diffTool('get_diff_threads'));
    case 'save_customer_need': return out(await genericSave('customerNeed', 'CustomerNeed', ['body','priority','customerId']));
    case 'delete_customer': return out(await gql(`mutation($id:String!){ customerDelete(id:$id){ success } }`, { id: args.id }));
    case 'delete_customer_need': return out(await gql(`mutation($id:String!){ customerNeedDelete(id:$id){ success } }`, { id: args.id }));
    case 'extract_images': return out(token ? (await mcpCall('extract_images', { markdown: args.markdown || args.text || '' })).content : { images: [...String(args.markdown || args.text || '').matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)].map(m => m[1]), note: 'No Linear token available; returned markdown image URLs only.' });
    case 'search_documentation': return out(token ? (await mcpCall('search_documentation', { query: args.query || '', page: args.page || 0 })).content : { url: `https://linear.app/docs/search?query=${encodeURIComponent(args.query || '')}`, note: 'No Linear token available; open this Linear docs search URL.' });
    default: die(`Unknown tool: ${tool}. See SKILL.md for supported Linear MCP-style tools.`);
  }
}
async function resolveDocument(id) {
  if (!id) return undefined;
  if (/^[0-9a-f-]{20,}$/i.test(id)) return id;
  const data = await gql(`query($id:String!){ document(id:$id){id} }`, { id });
  return data.document.id;
}
async function documentContentIdForComment() {
  if (args.document || args.documentId) {
    const data = await gql(`query($id:String!){ document(id:$id){documentContentId} }`, { id: args.document || args.documentId });
    return data.document.documentContentId;
  }
  if (args.milestone || args.milestoneId) {
    const data = await gql(`query($id:String!){ projectMilestone(id:$id){documentContent{id}} }`, { id: await resolve('milestone', args.milestone || args.milestoneId) });
    return data.projectMilestone.documentContent.id;
  }
  return undefined;
}
async function commentFilterArgs() {
  const filter = {};
  const issueId = await resolve('issue', args.issue || args.issueId);
  const projectId = await resolve('project', args.project || args.projectId);
  const initiativeId = await resolve('initiative', args.initiative || args.initiativeId);
  const documentId = await resolveDocument(args.document || args.documentId);
  const milestoneId = await resolve('milestone', args.milestone || args.milestoneId);
  if (issueId) filter.issue = { id: { eq: issueId } };
  if (projectId) filter.project = { id: { eq: projectId } };
  if (initiativeId) filter.initiative = { id: { eq: initiativeId } };
  if (documentId) filter.documentContent = { document: { id: { eq: documentId } } };
  if (milestoneId) filter.documentContent = { projectMilestone: { id: { eq: milestoneId } } };
  if (args.parentId) filter.parent = { id: { eq: args.parentId } };
  return filter;
}
async function listComments() {
  const filter = await commentFilterArgs();
  const data = await gql(`query($first:Int,$after:String,$filter:CommentFilter,$includeArchived:Boolean,$orderBy:PaginationOrderBy){ comments(first:$first, after:$after, filter:$filter, includeArchived:$includeArchived, orderBy:$orderBy){ nodes{${commentFields}} ${page} } }`, { first: args.limit || 50, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy });
  return data.comments;
}
async function saveComment() {
  if (args.id) return gql(`mutation($id:String!,$input:CommentUpdateInput!){ commentUpdate(id:$id,input:$input){ success comment{${commentFields}} } }`, { id: args.id, input: { body: args.body || args.comment || args.content } });
  const input = compact({
    issueId: await resolve('issue', args.issue || args.issueId),
    projectId: await resolve('project', args.project || args.projectId),
    initiativeId: await resolve('initiative', args.initiative || args.initiativeId),
    documentContentId: await documentContentIdForComment(),
    parentId: args.parentId,
    body: args.body || args.comment || args.content
  });
  return gql(`mutation($input:CommentCreateInput!){ commentCreate(input:$input){ success comment{${commentFields}} } }`, { input });
}
async function resolveNullable(kind, value, extra = {}) {
  if (value === undefined) return undefined;
  if (value === null) return null;
  return resolve(kind, value, extra);
}
async function resolveMany(kind, values, extra = {}) {
  const items = asArray(values);
  return items ? Promise.all(items.map(v => resolve(kind, v, extra))) : undefined;
}
async function saveIssue() {
  const teamId = await resolve('team', args.team || args.teamId);
  const projectId = await resolve('project', args.project || args.projectId, { teamId });
  const labelIds = args.labels ? await Promise.all(args.labels.map(l => resolve('label', l, { teamId }))) : undefined;
  const input = compactUndefined({
    title: args.title,
    description: args.description,
    teamId,
    projectId,
    stateId: await resolve('state', args.state || args.status || args.stateId, { teamId }),
    assigneeId: await resolveNullable('user', argValue('assignee', 'assigneeId')),
    delegateId: await resolveNullable('user', argValue('delegate', 'delegateId')),
    priority: args.priority,
    estimate: argValue('estimate'),
    cycleId: await resolveNullable('cycle', argValue('cycle', 'cycleId'), { teamId }),
    projectMilestoneId: await resolve('milestone', args.milestone || args.projectMilestone || args.milestoneId, { projectId }),
    parentId: await resolveNullable('issue', argValue('parent', 'parentId')),
    dueDate: argValue('dueDate'),
    labelIds
  });
  const data = args.id ? await gql(`mutation($id:String!,$input:IssueUpdateInput!){ issueUpdate(id:$id,input:$input){ success issue{${issueFields}} } }`, { id: args.id, input }) : await gql(`mutation($input:IssueCreateInput!){ issueCreate(input:$input){ success issue{${issueFields}} } }`, { input });
  const issue = data.issueUpdate?.issue || data.issueCreate?.issue;
  if (issue?.id) await applyIssuePostSave(issue.id);
  return data;
}
async function addIssueRelations(issueId, values, type, direction = 'outgoing') {
  const items = asArray(values);
  if (!items?.length) return;
  for (const value of items) {
    const otherId = await resolve('issue', value);
    const input = direction === 'incoming' ? { issueId: otherId, relatedIssueId: issueId, type } : { issueId, relatedIssueId: otherId, type };
    await gql(`mutation($input:IssueRelationCreateInput!){ issueRelationCreate(input:$input){ success } }`, { input });
  }
}
async function issueRelations(issueId) {
  const data = await gql(`query($id:String!){ issue(id:$id){ relations(first:100){nodes{id type issue{id identifier} relatedIssue{id identifier}}} inverseRelations(first:100){nodes{id type issue{id identifier} relatedIssue{id identifier}}} } }`, { id: issueId });
  return data.issue;
}
async function deleteIssueRelation(id) {
  await gql(`mutation($id:String!){ issueRelationDelete(id:$id){ success } }`, { id });
}
async function removeIssueRelations(issueId, values, type, direction = 'outgoing') {
  const items = asArray(values);
  if (!items?.length) return;
  const targetIds = new Set(await Promise.all(items.map(v => resolve('issue', v))));
  const rels = await issueRelations(issueId);
  const candidates = direction === 'incoming' ? rels.inverseRelations.nodes : rels.relations.nodes;
  for (const rel of candidates) {
    const otherId = direction === 'incoming' ? rel.issue.id : rel.relatedIssue.id;
    if (rel.type === type && targetIds.has(otherId)) await deleteIssueRelation(rel.id);
  }
}
async function removeDuplicateOf(issueId) {
  const rels = await issueRelations(issueId);
  for (const rel of rels.relations.nodes) if (rel.type === 'duplicate') await deleteIssueRelation(rel.id);
}
async function removeRelatedTo(issueId, values) {
  const items = asArray(values);
  if (!items?.length) return;
  const targetIds = new Set(await Promise.all(items.map(v => resolve('issue', v))));
  const rels = await issueRelations(issueId);
  for (const rel of rels.relations.nodes) if (rel.type === 'related' && targetIds.has(rel.relatedIssue.id)) await deleteIssueRelation(rel.id);
  for (const rel of rels.inverseRelations.nodes) if (rel.type === 'related' && targetIds.has(rel.issue.id)) await deleteIssueRelation(rel.id);
}
async function addIssueLinks(issueId, links) {
  if (!Array.isArray(links)) return;
  for (const link of links) await gql(`mutation($input:AttachmentCreateInput!){ attachmentCreate(input:$input){ success } }`, { input: compact({ issueId, url: link.url, title: link.title, subtitle: link.subtitle, metadata: link.metadata }) });
}
async function applyIssuePostSave(issueId) {
  await addIssueLinks(issueId, args.links);
  await addIssueRelations(issueId, args.relatedTo, 'related');
  await addIssueRelations(issueId, args.blocks, 'blocks');
  await addIssueRelations(issueId, args.blockedBy, 'blocks', 'incoming');
  if (Object.prototype.hasOwnProperty.call(args, 'duplicateOf')) {
    if (args.duplicateOf === null) await removeDuplicateOf(issueId);
    else await addIssueRelations(issueId, args.duplicateOf, 'duplicate');
  }
  await removeIssueRelations(issueId, args.removeBlocks, 'blocks');
  await removeIssueRelations(issueId, args.removeBlockedBy, 'blocks', 'incoming');
  await removeRelatedTo(issueId, args.removeRelatedTo);
}
async function currentProjectTeamIds(projectId) {
  const data = await gql(`query($id:String!){ project(id:$id){ teams(first:100){nodes{id}} } }`, { id: projectId });
  return data.project.teams.nodes.map(t => t.id);
}
async function projectTeamIdsForSave(projectId) {
  if (args.setTeams) return resolveMany('team', args.setTeams);
  if (args.addTeams || args.removeTeams) {
    const current = new Set(projectId ? await currentProjectTeamIds(projectId) : []);
    for (const id of await resolveMany('team', args.addTeams) || []) current.add(id);
    for (const id of await resolveMany('team', args.removeTeams) || []) current.delete(id);
    return [...current];
  }
  if (args.teams) return resolveMany('team', args.teams);
  if (args.team || args.teamId) return [await resolve('team', args.team || args.teamId)];
  return undefined;
}
async function projectInitiativeLinks(projectId) {
  const data = await gql(`query($id:String!){ project(id:$id){ initiativeToProjects(first:100){nodes{id initiative{id name}}} } }`, { id: projectId });
  return data.project.initiativeToProjects.nodes;
}
async function createInitiativeToProject(projectId, initiativeId) {
  await gql(`mutation($input:InitiativeToProjectCreateInput!){ initiativeToProjectCreate(input:$input){ success } }`, { input: { projectId, initiativeId } });
}
async function deleteInitiativeToProject(id) {
  await gql(`mutation($id:String!){ initiativeToProjectDelete(id:$id){ success } }`, { id });
}
async function applyProjectInitiatives(projectId) {
  if (!args.setInitiatives && !args.addInitiatives && !args.removeInitiatives) return;
  const links = await projectInitiativeLinks(projectId);
  const existing = new Map(links.map(link => [link.initiative.id, link.id]));
  if (args.setInitiatives) {
    const desired = new Set(await resolveMany('initiative', args.setInitiatives) || []);
    for (const [initiativeId, linkId] of existing) if (!desired.has(initiativeId)) await deleteInitiativeToProject(linkId);
    for (const initiativeId of desired) if (!existing.has(initiativeId)) await createInitiativeToProject(projectId, initiativeId);
    return;
  }
  for (const initiativeId of await resolveMany('initiative', args.addInitiatives) || []) if (!existing.has(initiativeId)) await createInitiativeToProject(projectId, initiativeId);
  for (const initiativeId of await resolveMany('initiative', args.removeInitiatives) || []) if (existing.has(initiativeId)) await deleteInitiativeToProject(existing.get(initiativeId));
}
async function saveProject() {
  const projectId = args.id || undefined;
  const teamIds = await projectTeamIdsForSave(projectId);
  const labelIds = await resolveMany('projectLabel', args.labels);
  const input = compactUndefined({
    name: args.name,
    description: args.summary || args.description,
    content: args.content || args.body || (args.summary ? args.description : undefined),
    icon: args.icon,
    color: args.color,
    priority: args.priority,
    statusId: await resolve('projectStatus', args.statusId || args.status || args.state),
    targetDate: args.targetDate,
    targetDateResolution: args.targetDateResolution,
    startDate: args.startDate,
    startDateResolution: args.startDateResolution,
    teamIds,
    labelIds,
    leadId: await resolveNullable('user', argValue('lead', 'leadId'))
  });
  const data = args.id ? await gql(`mutation($id:String!,$input:ProjectUpdateInput!){ projectUpdate(id:$id,input:$input){ success project{${projectFields}} } }`, { id: args.id, input }) : await gql(`mutation($input:ProjectCreateInput!){ projectCreate(input:$input){ success project{${projectFields}} } }`, { input });
  const project = data.projectUpdate?.project || data.projectCreate?.project;
  if (project?.id) await applyProjectInitiatives(project.id);
  return data;
}
async function saveMilestone() {
  const input = compact({ name: args.name, description: args.description, targetDate: args.targetDate, projectId: await resolve('project', args.project || args.projectId) });
  return args.id ? gql(`mutation($id:String!,$input:ProjectMilestoneUpdateInput!){ projectMilestoneUpdate(id:$id,input:$input){ success projectMilestone{${milestoneFields}} } }`, { id: args.id, input }) : gql(`mutation($input:ProjectMilestoneCreateInput!){ projectMilestoneCreate(input:$input){ success projectMilestone{${milestoneFields}} } }`, { input });
}
async function saveDocument() {
  const input = compactUndefined({ title: args.title, content: args.content || args.body, icon: args.icon, color: args.color, ...await documentTargetInput() });
  return args.id ? gql(`mutation($id:String!,$input:DocumentUpdateInput!){ documentUpdate(id:$id,input:$input){ success document{${documentFields}} } }`, { id: args.id, input }) : gql(`mutation($input:DocumentCreateInput!){ documentCreate(input:$input){ success document{${documentFields}} } }`, { input });
}
function headersToObject(headers) {
  return Object.fromEntries((headers || []).map(h => [h.key, h.value]));
}
function filenameFromUrl(url) {
  try {
    const path = new URL(url).pathname.split('/').filter(Boolean).pop();
    return path ? decodeURIComponent(path) : undefined;
  } catch {
    return undefined;
  }
}
async function prepareAttachmentUpload() {
  const issueId = await resolve('issue', args.issue || args.issueId);
  const filename = args.filename || (args.path || args.file ? basename(args.path || args.file) : undefined);
  if (!filename) die('prepare_attachment_upload requires filename.');
  if (!args.contentType) die('prepare_attachment_upload requires contentType.');
  if (!Number.isInteger(args.size) || args.size <= 0) die('prepare_attachment_upload requires a positive integer size.');
  const data = await gql(`mutation($filename:String!,$contentType:String!,$size:Int!,$metaData:JSON,$makePublic:Boolean){ fileUpload(filename:$filename, contentType:$contentType, size:$size, metaData:$metaData, makePublic:$makePublic){ success uploadFile{${uploadFileFields}} } }`, { filename, contentType: args.contentType, size: args.size, metaData: args.metaData || args.metadata, makePublic: args.makePublic ?? true });
  const uploadFile = data.fileUpload.uploadFile;
  const headers = headersToObject(uploadFile.headers);
  return { issueId, filename: uploadFile.filename, contentType: uploadFile.contentType, size: uploadFile.size, assetUrl: uploadFile.assetUrl, uploadRequest: { url: uploadFile.uploadUrl, headers }, headersArray: uploadFile.headers, title: args.title, subtitle: args.subtitle };
}
async function createAttachmentFromUpload() {
  const issueId = await resolve('issue', args.issue || args.issueId);
  const assetUrl = args.assetUrl || args.url;
  if (!assetUrl) die('create_attachment_from_upload requires assetUrl.');
  const title = args.title || args.filename || filenameFromUrl(assetUrl) || assetUrl;
  return gql(`mutation($input:AttachmentCreateInput!){ attachmentCreate(input:$input){ success attachment{id title subtitle url createdAt updatedAt issue{id identifier title}} } }`, { input: compact({ issueId, title, url: assetUrl, subtitle: args.subtitle, metadata: args.metadata }) });
}
async function uploadBytes(filename, contentType, bytes) {
  const prepared = await prepareAttachmentUploadWith({ filename, contentType, size: bytes.length, metaData: args.metaData || args.metadata, makePublic: true });
  const res = await fetch(prepared.uploadRequest.url, { method: 'PUT', headers: prepared.uploadRequest.headers, body: bytes });
  if (!res.ok) die(`Upload failed: ${res.status} ${res.statusText} ${await res.text().catch(() => '')}`.trim());
  return prepared;
}
async function prepareAttachmentUploadWith({ filename, contentType, size, metaData, makePublic }) {
  const data = await gql(`mutation($filename:String!,$contentType:String!,$size:Int!,$metaData:JSON,$makePublic:Boolean){ fileUpload(filename:$filename, contentType:$contentType, size:$size, metaData:$metaData, makePublic:$makePublic){ success uploadFile{${uploadFileFields}} } }`, { filename, contentType, size, metaData, makePublic });
  const uploadFile = data.fileUpload.uploadFile;
  return { filename: uploadFile.filename, contentType: uploadFile.contentType, size: uploadFile.size, assetUrl: uploadFile.assetUrl, uploadRequest: { url: uploadFile.uploadUrl, headers: headersToObject(uploadFile.headers) }, headersArray: uploadFile.headers };
}
async function createAttachment() {
  if (args.url && !args.base64Content && !args.path && !args.file) {
    return gql(`mutation($input:AttachmentCreateInput!){ attachmentCreate(input:$input){ success attachment{id title url createdAt issue{id identifier}} } }`, { input: compact({ issueId: await resolve('issue', args.issue || args.issueId), title: args.title, url: args.url, subtitle: args.subtitle, metadata: args.metadata }) });
  }
  const filePath = args.path || args.file;
  const filename = args.filename || (filePath ? basename(filePath) : undefined);
  const contentType = args.contentType;
  if (!filename) die('create_attachment requires filename when uploading content.');
  if (!contentType) die('create_attachment requires contentType when uploading content.');
  const issueId = await resolve('issue', args.issue || args.issueId);
  const bytes = filePath ? readFileSync(filePath) : Buffer.from(args.base64Content || '', 'base64');
  if (!bytes.length) die('create_attachment requires non-empty base64Content, path, or file.');
  const prepared = await uploadBytes(filename, contentType, bytes);
  const linked = await gql(`mutation($input:AttachmentCreateInput!){ attachmentCreate(input:$input){ success attachment{id title subtitle url createdAt updatedAt issue{id identifier title}} } }`, { input: compact({ issueId, title: args.title || filename, url: prepared.assetUrl, subtitle: args.subtitle, metadata: args.metadata }) });
  return { ...linked, upload: { assetUrl: prepared.assetUrl, filename: prepared.filename, contentType: prepared.contentType, size: prepared.size } };
}
async function diffTool(name) {
  const result = await mcpCall(name, args);
  if (result.raw?.isError) return { unsupported: true, tool: name, reason: 'Linear GraphQL does not expose diff/review objects for personal API-key access, and the official Linear MCP diff tool returned an error for this token/request.', mcpError: result.content };
  return result.content;
}
function assertProjectUpdateType() {
  const type = String(args.type || 'project').toLowerCase();
  if (type !== 'project') die(`Only project status updates are supported through Linear GraphQL; got type: ${args.type}`);
}
async function listStatusUpdates() {
  assertProjectUpdateType();
  const projectId = await resolve('project', args.project || args.projectId);
  const filter = projectId ? { project: { id: { eq: projectId } } } : undefined;
  return connPaged('ProjectUpdate', 'projectUpdates', { first: args.limit || 50, after: args.cursor || args.after, filter, includeArchived: args.includeArchived, orderBy: args.orderBy }, `id body health createdAt updatedAt user{id name} project{id name}`);
}
async function saveStatusUpdate() {
  assertProjectUpdateType();
  const input = compact({ body: args.body || args.content, bodyData: args.bodyData, health: args.health });
  if (args.id) return gql(`mutation($id:String!,$input:ProjectUpdateUpdateInput!){ projectUpdateUpdate(id:$id,input:$input){ success projectUpdate{id body health project{id name}} } }`, { id: args.id, input });
  input.projectId = await resolve('project', args.project || args.projectId);
  return gql(`mutation($input:ProjectUpdateCreateInput!){ projectUpdateCreate(input:$input){ success projectUpdate{id body health project{id name}} } }`, { input: compact(input) });
}
async function saveCustomer() {
  const input = compact({
    name: args.name,
    domains: asArray(args.domains || args.domain),
    externalIds: asArray(args.externalIds || args.externalId),
    logoUrl: args.logoUrl,
    mainSourceId: args.mainSourceId,
    revenue: args.revenue,
    size: args.size,
    slackChannelId: args.slackChannelId,
    ownerId: await resolve('user', args.owner || args.ownerId),
    statusId: await resolve('customerStatus', args.status || args.statusId),
    tierId: await resolve('customerTier', args.tier || args.tierId)
  });
  return args.id ? gql(`mutation($id:String!,$input:CustomerUpdateInput!){ customerUpdate(id:$id,input:$input){ success customer{${customerFields}} } }`, { id: args.id, input }) : gql(`mutation($input:CustomerCreateInput!){ customerCreate(input:$input){ success customer{${customerFields}} } }`, { input });
}
async function listInitiatives() {
  const ownerId = await resolve('user', args.owner || args.ownerId);
  const leadTeamId = await resolve('team', args.leadTeam || args.leadTeamId || args.team || args.teamId);
  const filter = {};
  if (ownerId) filter.owner = { id: { eq: ownerId } };
  if (leadTeamId) filter.leadTeam = { id: { eq: leadTeamId } };
  if (args.status) filter.status = { eq: args.status };
  if (args.query || args.search) filter.or = [{ name: { containsIgnoreCase: args.query || args.search } }, { slugId: { containsIgnoreCase: args.query || args.search } }];
  return connPaged('Initiative', 'initiatives', { first: args.limit || 50, after: args.cursor || args.after, filter: Object.keys(filter).length ? filter : undefined, includeArchived: args.includeArchived, orderBy: args.orderBy }, initiativeFields);
}
async function saveInitiative() {
  const input = compact({
    name: args.name,
    description: args.description,
    content: args.content || args.body,
    status: args.status,
    priority: args.priority,
    color: args.color,
    icon: args.icon,
    targetDate: args.targetDate,
    targetDateResolution: args.targetDateResolution,
    ownerId: await resolve('user', args.owner || args.ownerId),
    leadTeamId: await resolve('team', args.leadTeam || args.leadTeamId || args.team || args.teamId)
  });
  return args.id ? gql(`mutation($id:String!,$input:InitiativeUpdateInput!){ initiativeUpdate(id:$id,input:$input){ success initiative{${initiativeFields}} } }`, { id: args.id, input }) : gql(`mutation($input:InitiativeCreateInput!){ initiativeCreate(input:$input){ success initiative{${initiativeFields}} } }`, { input });
}
async function genericSave(prefix, type, keys) {
  const input = compact(Object.fromEntries(keys.map(k => [k, args[k]])));
  const cap = prefix[0].toUpperCase() + prefix.slice(1);
  return args.id ? gql(`mutation($id:String!,$input:${type}UpdateInput!){ ${prefix}Update(id:$id,input:$input){ success } }`, { id: args.id, input }) : gql(`mutation($input:${type}CreateInput!){ ${prefix}Create(input:$input){ success } }`, { input });
}
main().catch(e => die(e.stack || e.message));
