#!/usr/bin/env node
'use strict';

const { execFileSync } = require('node:child_process');

const API_BASE = 'https://api.clickup.com/api/v2';
const KEYCHAIN_SERVICE = 'pi ClickUp Skill';
const KEYCHAIN_ACCOUNT = 'CLICKUP_API_KEY';
const SETUP_GUIDANCE = 'Set CLICKUP_API_KEY/CLICKUP_TOKEN or store it in macOS Keychain: security add-generic-password -a CLICKUP_API_KEY -s "pi ClickUp Skill" -w "pk_..." -U';

const COMMANDS = [
  'authenticate',
  'list_workspaces',
  'list_spaces',
  'list_folders',
  'list_lists',
  'list_users',
  'list_task_statuses',
  'get_task',
  'list_tasks',
  'save_task',
  'delete_task',
  'get_task_by_custom_id',
  'list_task_comments',
  'save_task_comment',
  'list_task_tags',
  'list_custom_fields',
  'set_custom_field_value'
];

class ClickUpError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = 'ClickUpError';
    this.code = options.code;
    this.status = options.status;
    this.details = options.details;
  }
}

function hasOwn(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function presentValue(value) {
  return value !== undefined && value !== null && !(typeof value === 'string' && value.trim() === '');
}

function sameValue(left, right) {
  if (typeof left === 'object' || typeof right === 'object') {
    try { return JSON.stringify(left) === JSON.stringify(right); } catch { return false; }
  }
  return String(left) === String(right);
}

function aliasValue(args, names, label = names[0]) {
  const entries = names.filter(name => hasOwn(args, name) && args[name] !== undefined);
  if (!entries.length) return undefined;
  const first = args[entries[0]];
  for (const name of entries.slice(1)) {
    if (!sameValue(first, args[name])) {
      throw new ClickUpError(`Conflicting values supplied for ${label}: ${entries.join(', ')}.`, { code: 'conflicting_arguments' });
    }
  }
  return first;
}

function requireValue(value, message) {
  if (!presentValue(value)) throw new ClickUpError(message, { code: 'invalid_arguments' });
  return value;
}

function asArray(value) {
  if (value === undefined || value === null) return undefined;
  return Array.isArray(value) ? value : [value];
}

function booleanValue(value, name) {
  if (value === undefined || value === null) return undefined;
  if (typeof value === 'boolean') return value;
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new ClickUpError(`${name} must be a boolean.`, { code: 'invalid_arguments' });
}

function integerValue(value, name, { allowNull = false } = {}) {
  if (value === null && allowNull) return null;
  if (typeof value === 'string' && /^-?\d+$/.test(value.trim())) value = Number(value);
  if (!Number.isInteger(value)) throw new ClickUpError(`${name} must be an integer.`, { code: 'invalid_arguments' });
  return value;
}

function tokenFromEnvironment(env) {
  for (const name of ['CLICKUP_API_KEY', 'CLICKUP_TOKEN']) {
    const value = typeof env?.[name] === 'string' ? env[name].trim() : env?.[name];
    if (presentValue(value)) return String(value);
  }
  return undefined;
}

function getToken({ env = process.env, platform = process.platform, execFileSync: run = execFileSync } = {}) {
  const environmentToken = tokenFromEnvironment(env);
  if (environmentToken) return environmentToken;
  if (platform !== 'darwin') return undefined;
  try {
    const token = run('security', [
      'find-generic-password',
      '-s', KEYCHAIN_SERVICE,
      '-a', KEYCHAIN_ACCOUNT,
      '-w'
    ], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    return typeof token === 'string' && token.trim() ? token.trim() : undefined;
  } catch {
    return undefined;
  }
}

function redact(value, token) {
  const text = String(value ?? '');
  return token ? text.split(token).join('[REDACTED]') : text;
}

function pathPart(value) {
  return encodeURIComponent(String(value));
}

function addQuery(url, query = {}) {
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    if (Array.isArray(value)) {
      for (const item of value) {
        if (item !== undefined && item !== null) url.searchParams.append(key, String(item));
      }
    } else {
      url.searchParams.set(key, typeof value === 'boolean' ? String(value) : String(value));
    }
  }
  return url;
}

function responseHeader(response, name) {
  if (response?.headers?.get) return response.headers.get(name);
  if (response?.headers && typeof response.headers === 'object') {
    const wanted = name.toLowerCase();
    const key = Object.keys(response.headers).find(candidate => candidate.toLowerCase() === wanted);
    return key ? response.headers[key] : undefined;
  }
  return undefined;
}

function retryDelay(header) {
  if (!header) return 0;
  const seconds = Number(header);
  if (Number.isFinite(seconds)) return Math.max(0, seconds * 1000);
  const date = Date.parse(header);
  return Number.isNaN(date) ? 0 : Math.max(0, date - Date.now());
}

function sleep(milliseconds) {
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

async function readResponse(response) {
  let text = '';
  if (typeof response?.text === 'function') {
    text = await response.text();
  } else if (typeof response?.json === 'function') {
    const value = await response.json();
    return value;
  }
  if (!text || !text.trim()) return {};
  try { return JSON.parse(text); } catch { return { __text: text }; }
}

function apiMessage(data) {
  if (typeof data === 'string' && data.trim()) return data;
  if (!data || typeof data !== 'object') return undefined;
  if (typeof data.__text === 'string' && data.__text.trim()) return data.__text;
  for (const key of ['err', 'message', 'error', 'detail']) {
    if (data[key] === undefined || data[key] === null) continue;
    if (typeof data[key] === 'string' && data[key].trim()) return data[key];
    try { return JSON.stringify(data[key]); } catch { return undefined; }
  }
  return undefined;
}

class ClickUpClient {
  constructor(token, { fetch = globalThis.fetch, sleep: wait = sleep } = {}) {
    this.token = token;
    this.fetch = fetch;
    this.sleep = wait;
  }

  async request(method, path, { query, body, headers = {} } = {}) {
    if (typeof this.fetch !== 'function') {
      throw new ClickUpError('Node.js fetch is unavailable. ClickUp requires Node.js 18 or newer.', { code: 'fetch_unavailable' });
    }
    const url = addQuery(new URL(`${API_BASE}${path.startsWith('/') ? path : `/${path}`}`), query);
    const requestHeaders = {
      accept: 'application/json',
      'content-type': 'application/json',
      Authorization: this.token,
      ...headers
    };
    const requestOptions = {
      method,
      headers: requestHeaders
    };
    if (body !== undefined) requestOptions.body = JSON.stringify(body);

    for (let attempt = 0; attempt < 2; attempt += 1) {
      let response;
      try {
        response = await this.fetch(url.toString(), requestOptions);
      } catch (error) {
        throw new ClickUpError(`ClickUp request failed: ${redact(error?.message || error, this.token)}`, { code: 'network_error' });
      }
      const data = await readResponse(response);
      const status = Number(response?.status || 0);
      const ok = response?.ok === true || (status >= 200 && status < 300);
      if (ok) return data;

      if (status === 429 && attempt === 0) {
        await this.sleep(retryDelay(responseHeader(response, 'retry-after')));
        continue;
      }

      const message = apiMessage(data);
      const statusText = response?.statusText ? ` ${redact(response.statusText, this.token)}` : '';
      const suffix = message ? `: ${redact(message, this.token)}` : '';
      const guidance = status === 401 || status === 403
        ? ' Check the personal token and its ClickUp workspace permissions.'
        : '';
      throw new ClickUpError(`ClickUp API request failed (${status}${statusText})${suffix}.${guidance}`, {
        code: 'clickup_http_error',
        status,
        details: message ? { message: redact(message, this.token) } : undefined
      });
    }
    throw new ClickUpError('ClickUp API request failed after one rate-limit retry.', { code: 'rate_limit_error', status: 429 });
  }
}

function candidateDetails(items) {
  return items.slice(0, 25).map(item => ({
    id: item?.id,
    name: item?.name,
    username: item?.username,
    email: item?.email,
    parent_folder: item?.parent_folder
  }));
}

function displayCandidates(items) {
  try { return JSON.stringify(candidateDetails(items)); } catch { return '[]'; }
}

function exactMatches(items, value, fields) {
  const query = String(value).toLocaleLowerCase();
  return items.filter(item => fields.some(field => {
    const candidate = item?.[field];
    return candidate !== undefined && candidate !== null && String(candidate).toLocaleLowerCase() === query;
  }));
}

function uniqueById(items) {
  const seen = new Set();
  return items.filter(item => {
    const key = String(item?.id ?? '');
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function resolveMatch(kind, value, items, fields) {
  const matches = exactMatches(items, value, fields);
  if (matches.length === 1) return matches[0];
  if (matches.length > 1) {
    throw new ClickUpError(`Ambiguous ${kind} "${String(value)}". Candidates: ${displayCandidates(matches)}`, {
      code: 'ambiguous_resource',
      details: { candidates: candidateDetails(matches) }
    });
  }
  throw new ClickUpError(`Could not resolve ${kind} "${String(value)}". Candidates: ${displayCandidates(items)}`, {
    code: 'resource_not_found',
    details: { candidates: candidateDetails(items) }
  });
}

function isNumericId(value) {
  return (typeof value === 'number' && Number.isInteger(value) && value >= 0) || (typeof value === 'string' && /^\d+$/.test(value.trim()));
}

function workspaceValue(args) {
  return aliasValue(args, ['workspace', 'team', 'teamId'], 'workspace');
}

function spaceValue(args) {
  return aliasValue(args, ['space', 'spaceId'], 'space');
}

function folderValue(args) {
  return aliasValue(args, ['folder', 'folderId'], 'folder');
}

function listValue(args) {
  return aliasValue(args, ['list', 'listId'], 'list');
}

function taskValue(args) {
  return aliasValue(args, ['id', 'task', 'taskId'], 'task');
}

function customTaskValue(args) {
  return aliasValue(args, ['customTaskId', 'custom_task_id', 'customId', 'custom_id', 'id', 'task', 'taskId'], 'customTaskId/task');
}

function customTaskIdsValue(args) {
  return aliasValue(args, ['customTaskIds', 'custom_task_ids'], 'customTaskIds');
}

function memberUser(member) {
  return member?.user || member;
}

function userFields(user) {
  return ['id', 'username', 'email', 'name', 'display_name', 'displayName']
    .map(field => user?.[field])
    .filter(value => value !== undefined && value !== null);
}

function userCandidateDetails(users) {
  return users.slice(0, 25).map(user => ({
    id: user?.id,
    username: user?.username,
    email: user?.email,
    name: user?.name || user?.display_name || user?.displayName
  }));
}

class ClickUpContext {
  constructor(args, client) {
    this.args = args;
    this.client = client;
    this.cache = new Map();
  }

  async workspaces() {
    if (!this.cache.has('workspaces')) this.cache.set('workspaces', this.client.request('GET', '/team'));
    return this.cache.get('workspaces');
  }

  async resolveWorkspace(value, { required = true } = {}) {
    if (!presentValue(value)) {
      if (required) throw new ClickUpError('A workspace is required. Use workspace, team, or teamId.', { code: 'missing_scope' });
      return undefined;
    }
    if (isNumericId(value)) return String(value);
    const teams = (await this.workspaces()).teams || [];
    return resolveMatch('workspace', value, teams, ['id', 'name']).id;
  }

  async spaces(workspaceId, query = {}) {
    const key = `spaces:${workspaceId}:${JSON.stringify(query)}`;
    if (!this.cache.has(key)) this.cache.set(key, this.client.request('GET', `/team/${pathPart(workspaceId)}/space`, { query }));
    return this.cache.get(key);
  }

  async resolveSpace(value, { workspace = workspaceValue(this.args), required = true } = {}) {
    if (!presentValue(value)) {
      if (required) throw new ClickUpError('A space is required. Use space or spaceId.', { code: 'missing_scope' });
      return undefined;
    }
    if (isNumericId(value)) return String(value);
    if (!presentValue(workspace)) {
      throw new ClickUpError(`Space name "${String(value)}" requires workspace/team/teamId scope.`, { code: 'missing_scope' });
    }
    const workspaceId = await this.resolveWorkspace(workspace);
    const resources = (await this.spaces(workspaceId)).spaces || [];
    return resolveMatch('space', value, resources, ['id', 'name']).id;
  }

  async folders(spaceId, query = {}) {
    const key = `folders:${spaceId}:${JSON.stringify(query)}`;
    if (!this.cache.has(key)) this.cache.set(key, this.client.request('GET', `/space/${pathPart(spaceId)}/folder`, { query }));
    return this.cache.get(key);
  }

  async resolveFolder(value, { space = spaceValue(this.args), workspace = workspaceValue(this.args), required = true } = {}) {
    if (!presentValue(value)) {
      if (required) throw new ClickUpError('A folder is required. Use folder or folderId.', { code: 'missing_scope' });
      return undefined;
    }
    if (isNumericId(value)) return String(value);
    if (!presentValue(space)) {
      throw new ClickUpError(`Folder name "${String(value)}" requires space/spaceId scope.`, { code: 'missing_scope' });
    }
    const spaceId = await this.resolveSpace(space, { workspace });
    const resources = (await this.folders(spaceId)).folders || [];
    return resolveMatch('folder', value, resources, ['id', 'name']).id;
  }

  async listsInFolder(folderId, query = {}) {
    const key = `lists:folder:${folderId}:${JSON.stringify(query)}`;
    if (!this.cache.has(key)) this.cache.set(key, this.client.request('GET', `/folder/${pathPart(folderId)}/list`, { query }));
    return this.cache.get(key);
  }

  async listsInSpace(spaceId, query = {}) {
    const key = `lists:space:${spaceId}:${JSON.stringify(query)}`;
    if (!this.cache.has(key)) this.cache.set(key, this.client.request('GET', `/space/${pathPart(spaceId)}/list`, { query }));
    return this.cache.get(key);
  }

  async resolveList(value, { folder = folderValue(this.args), space = spaceValue(this.args), workspace = workspaceValue(this.args), required = true } = {}) {
    if (!presentValue(value)) {
      if (required) throw new ClickUpError('A list is required. Use list or listId.', { code: 'missing_scope' });
      return undefined;
    }
    if (isNumericId(value)) return String(value);
    if (presentValue(folder)) {
      const folderId = await this.resolveFolder(folder, { space, workspace });
      const resources = (await this.listsInFolder(folderId)).lists || [];
      return resolveMatch('list', value, resources, ['id', 'name']).id;
    }
    if (presentValue(space)) {
      const spaceId = await this.resolveSpace(space, { workspace });
      const resources = (await this.listsInSpace(spaceId)).lists || [];
      return resolveMatch('list', value, resources, ['id', 'name']).id;
    }
    throw new ClickUpError(`List name "${String(value)}" requires folder/folderId or space/spaceId scope.`, { code: 'missing_scope' });
  }

  async resolveUser(value, { workspace = workspaceValue(this.args) } = {}) {
    if (!presentValue(value)) throw new ClickUpError('User values must be non-empty.', { code: 'invalid_arguments' });
    if (isNumericId(value)) return Number(value);
    if (!presentValue(workspace)) {
      throw new ClickUpError(`User name "${String(value)}" requires workspace/team/teamId scope.`, { code: 'missing_scope' });
    }
    const workspaceId = await this.resolveWorkspace(workspace);
    const team = (await this.workspaces()).teams?.find(item => String(item.id) === String(workspaceId));
    const users = uniqueById((team?.members || []).map(memberUser));
    const matches = users.filter(user => userFields(user).some(candidate => String(candidate).toLocaleLowerCase() === String(value).toLocaleLowerCase()));
    if (matches.length === 1) return Number(matches[0].id);
    if (matches.length > 1) {
      throw new ClickUpError(`Ambiguous user "${String(value)}". Candidates: ${JSON.stringify(userCandidateDetails(matches))}`, {
        code: 'ambiguous_resource',
        details: { candidates: userCandidateDetails(matches) }
      });
    }
    throw new ClickUpError(`Could not resolve user "${String(value)}" in workspace "${String(workspaceId)}". Candidates: ${JSON.stringify(userCandidateDetails(users))}`, {
      code: 'resource_not_found',
      details: { candidates: userCandidateDetails(users) }
    });
  }

  async resolveUsers(value, options = {}) {
    if (value && typeof value === 'object' && !Array.isArray(value) && (hasOwn(value, 'add') || hasOwn(value, 'rem'))) {
      const result = {};
      for (const key of ['add', 'rem']) {
        if (hasOwn(value, key)) result[key] = await this.resolveUsers(value[key], options);
      }
      return result;
    }
    const values = asArray(value) || [];
    return Promise.all(values.map(item => this.resolveUser(item, options)));
  }

  async task(taskId, query = {}) {
    return this.client.request('GET', `/task/${pathPart(taskId)}`, { query });
  }

  async syncTaskTags(taskId, desiredTags, query, currentTask) {
    const current = currentTask || await this.task(taskId, query);
    const existing = Array.isArray(current.tags) ? current.tags.map(tag => typeof tag === 'string' ? tag : tag?.name).filter(Boolean) : [];
    const desired = [...new Set(desiredTags.map(tag => String(tag)))];
    const existingSet = new Set(existing);
    const desiredSet = new Set(desired);
    const removed = existing.filter(tag => !desiredSet.has(tag));
    const added = desired.filter(tag => !existingSet.has(tag));
    for (const tag of removed) {
      await this.client.request('DELETE', `/task/${pathPart(taskId)}/tag/${pathPart(tag)}`, { query });
    }
    for (const tag of added) {
      await this.client.request('POST', `/task/${pathPart(taskId)}/tag/${pathPart(tag)}`, { query });
    }
    return { added, removed };
  }
}

function customTaskQuery(args, context, { force = false } = {}) {
  return (async () => {
    const explicit = customTaskIdsValue(args);
    const custom = force || booleanValue(explicit, 'customTaskIds') === true;
    if (!custom) return {};
    const workspace = workspaceValue(args);
    if (!presentValue(workspace)) {
      throw new ClickUpError('Custom task IDs require workspace/team/teamId so ClickUp can identify the Workspace.', { code: 'missing_scope' });
    }
    return {
      custom_task_ids: true,
      team_id: await context.resolveWorkspace(workspace)
    };
  })();
}

function optionalQuery(args, query, name, aliases = [name]) {
  const value = aliasValue(args, aliases, name);
  if (value !== undefined && value !== null) query[name] = value;
}

function arrayQuery(args, query, outputName, aliases = [outputName], { json = false } = {}) {
  const value = aliasValue(args, aliases, outputName);
  if (value === undefined || value === null) return;
  if (json && typeof value === 'string') {
    query[outputName] = value;
    return;
  }
  const values = Array.isArray(value) ? value : [value];
  query[outputName] = json ? JSON.stringify(values) : values;
}

function jsonArrayValue(value) {
  if (typeof value === 'string') return value;
  return JSON.stringify(asArray(value));
}

async function listTaskQuery(args, context) {
  const query = {};
  for (const [outputName, aliases] of [
    ['archived', ['archived']],
    ['include_markdown_description', ['includeMarkdownDescription']],
    ['page', ['page']],
    ['order_by', ['orderBy']],
    ['reverse', ['reverse']],
    ['subtasks', ['subtasks']],
    ['include_closed', ['includeClosed']],
    ['include_timl', ['includeTiml']],
    ['due_date_gt', ['dueDateGt']],
    ['due_date_lt', ['dueDateLt']],
    ['date_created_gt', ['dateCreatedGt']],
    ['date_created_lt', ['dateCreatedLt']],
    ['date_updated_gt', ['dateUpdatedGt']],
    ['date_updated_lt', ['dateUpdatedLt']],
    ['date_done_gt', ['dateDoneGt']],
    ['date_done_lt', ['dateDoneLt']]
  ]) optionalQuery(args, query, outputName, aliases);

  for (const [outputName, aliases] of [
    ['statuses[]', ['statuses', 'status']],
    ['assignees[]', ['assignees', 'assignee']],
    ['watchers[]', ['watchers', 'watcher']],
    ['tags[]', ['tags', 'tag']],
    ['custom_items[]', ['customItems', 'custom_items']]
  ]) {
    const value = aliasValue(args, aliases, outputName);
    if (value === undefined || value === null) continue;
    let values = Array.isArray(value) ? value : [value];
    if (outputName === 'assignees[]' || outputName === 'watchers[]') values = await context.resolveUsers(values);
    query[outputName] = values;
  }
  arrayQuery(args, query, 'custom_fields', ['customFields', 'custom_fields'], { json: true });
  arrayQuery(args, query, 'custom_field', ['customField', 'custom_field'], { json: true });
  return query;
}

async function taskIdAndQuery(args, context, { forceCustom = false } = {}) {
  const taskId = requireValue(taskValue(args), 'A task ID is required. Use id, task, or taskId.');
  return { taskId: String(taskId), query: await customTaskQuery(args, context, { force: forceCustom }) };
}

async function buildTaskBody(args, context, mode) {
  const body = {};
  const name = aliasValue(args, ['name', 'title'], 'name/title');
  if (name !== undefined) {
    if (!presentValue(name)) throw new ClickUpError('name/title must be a non-empty string.', { code: 'invalid_arguments' });
    body.name = String(name);
  } else if (mode === 'create') {
    throw new ClickUpError('Creating a task requires name or title.', { code: 'invalid_arguments' });
  }

  const description = aliasValue(args, ['description'], 'description');
  if (description !== undefined) {
    if (description === null) throw new ClickUpError('description must be a string. Use a single space to clear it on update.', { code: 'invalid_arguments' });
    body.description = String(description);
  }

  const status = aliasValue(args, ['status'], 'status');
  if (status !== undefined) body.status = String(requireValue(status, 'status must be non-empty.'));

  const priority = aliasValue(args, ['priority'], 'priority');
  if (priority !== undefined) body.priority = mode === 'create' ? integerValue(priority, 'priority', { allowNull: true }) : integerValue(priority, 'priority');

  const workspace = workspaceValue(args);
  const assignee = aliasValue(args, ['assignee', 'assignees'], 'assignee/assignees');
  if (assignee !== undefined) {
    if (assignee === null) throw new ClickUpError('assignee/assignees cannot be null; use ClickUp user IDs or names.', { code: 'invalid_arguments' });
    if (mode === 'create') body.assignees = await context.resolveUsers(assignee, { workspace });
    else body.assignees = await context.resolveUsers({ add: assignee }, { workspace });
  }

  const tags = aliasValue(args, ['tags'], 'tags');
  if (tags !== undefined) {
    const tagValues = asArray(tags) || [];
    if (tagValues.some(tag => !presentValue(tag))) throw new ClickUpError('tags must contain non-empty tag names.', { code: 'invalid_arguments' });
    if (mode === 'create') body.tags = tagValues.map(String);
  }

  for (const [inputName, outputName] of [['dueDate', 'due_date'], ['startDate', 'start_date']]) {
    const value = aliasValue(args, [inputName], inputName);
    if (value !== undefined) body[outputName] = toEpochMillis(value, inputName);
  }

  const timeEstimate = aliasValue(args, ['timeEstimate'], 'timeEstimate');
  if (timeEstimate !== undefined) body.time_estimate = integerValue(timeEstimate, 'timeEstimate');

  const parent = aliasValue(args, ['parent'], 'parent');
  if (parent !== undefined) {
    if (mode === 'update' && parent === null) throw new ClickUpError('ClickUp cannot remove a parent through Update Task; parent must be a task ID when updating.', { code: 'invalid_arguments' });
    body.parent = parent === null ? null : String(requireValue(parent, 'parent must be a task ID.'));
  }

  const notifyAll = aliasValue(args, ['notifyAll'], 'notifyAll');
  if (notifyAll !== undefined) {
    if (mode === 'update') throw new ClickUpError('notifyAll is supported when creating a task, not by ClickUp Update Task.', { code: 'unsupported_argument' });
    body.notify_all = booleanValue(notifyAll, 'notifyAll');
  }

  return { body, tags: tags === undefined ? undefined : (asArray(tags) || []).map(String) };
}

function toEpochMillis(value, name) {
  if (value === null || value === undefined) throw new ClickUpError(`${name} must be an ISO date, epoch milliseconds, or Date-compatible string.`, { code: 'invalid_arguments' });
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new ClickUpError(`${name} must be a finite date value.`, { code: 'invalid_arguments' });
    return Math.trunc(value);
  }
  if (typeof value === 'string' && /^\d+(?:\.\d+)?$/.test(value.trim())) return Math.trunc(Number(value));
  const parsed = Date.parse(String(value));
  if (Number.isNaN(parsed)) throw new ClickUpError(`${name} must be a valid ISO date or epoch milliseconds.`, { code: 'invalid_arguments' });
  return parsed;
}

async function listWorkspaces(context) {
  return context.workspaces();
}

async function listSpaces(context) {
  const workspaceId = await context.resolveWorkspace(workspaceValue(context.args));
  return context.spaces(workspaceId, { archived: booleanValue(context.args.archived, 'archived') });
}

async function listFolders(context) {
  const spaceId = await context.resolveSpace(spaceValue(context.args));
  return context.folders(spaceId, { archived: booleanValue(context.args.archived, 'archived') });
}

async function listLists(context) {
  const folder = folderValue(context.args);
  const space = spaceValue(context.args);
  const list = listValue(context.args);
  if (!presentValue(folder) && !presentValue(space)) {
    throw new ClickUpError('list_lists requires folder/folderId or space/spaceId. Space lists are folderless lists; folder lists use the folder endpoint.', { code: 'missing_scope' });
  }
  const query = { archived: booleanValue(context.args.archived, 'archived') };
  if (presentValue(folder)) {
    const folderId = await context.resolveFolder(folder, { space });
    const result = await context.listsInFolder(folderId, query);
    if (!presentValue(list)) return result;
    return { ...result, selected_list_id: await context.resolveList(list, { folder, space }) };
  }
  const spaceId = await context.resolveSpace(space);
  const result = await context.listsInSpace(spaceId, query);
  if (!presentValue(list)) return result;
  return { ...result, selected_list_id: await context.resolveList(list, { space }) };
}

function filterUsers(users, query) {
  if (!presentValue(query)) return users;
  const needle = String(query).toLocaleLowerCase();
  return users.filter(user => userFields(user).some(value => String(value).toLocaleLowerCase().includes(needle)));
}

async function listUsers(context) {
  const workspace = workspaceValue(context.args);
  const query = aliasValue(context.args, ['query', 'search'], 'query/search');
  const teams = (await context.workspaces()).teams || [];
  if (presentValue(workspace)) {
    const workspaceId = await context.resolveWorkspace(workspace);
    const team = teams.find(item => String(item.id) === String(workspaceId));
    const users = filterUsers(uniqueById((team?.members || []).map(memberUser)), query);
    return { workspace: { id: String(workspaceId), name: team?.name }, users };
  }
  const users = filterUsers(uniqueById(teams.flatMap(team => (team.members || []).map(memberUser))), query);
  return { users, workspaces: teams.map(team => ({ id: team.id, name: team.name })) };
}

async function listTaskStatuses(context) {
  const args = context.args;
  const list = listValue(args);
  const folder = folderValue(args);
  const space = spaceValue(args);
  let type;
  let value;
  if (presentValue(list)) {
    type = 'list';
    value = list;
  } else if (presentValue(folder)) {
    type = 'folder';
    value = folder;
  } else if (presentValue(space)) {
    type = 'space';
    value = space;
  } else {
    throw new ClickUpError('list_task_statuses requires a space/spaceId, folder/folderId, or list/listId target.', { code: 'missing_scope' });
  }
  let id;
  let resource;
  if (type === 'space') {
    id = await context.resolveSpace(value);
    resource = await context.client.request('GET', `/space/${pathPart(id)}`);
  } else if (type === 'folder') {
    id = await context.resolveFolder(value);
    resource = await context.client.request('GET', `/folder/${pathPart(id)}`);
  } else {
    id = await context.resolveList(value);
    resource = await context.client.request('GET', `/list/${pathPart(id)}`);
  }
  return { scope: { type, id }, statuses: resource.statuses || [] };
}

async function getTask(context) {
  const { taskId, query } = await taskIdAndQuery(context.args, context);
  const extra = {
    include_subtasks: booleanValue(context.args.includeSubtasks, 'includeSubtasks'),
    include_markdown_description: booleanValue(context.args.includeMarkdownDescription, 'includeMarkdownDescription')
  };
  if (context.args.customFields !== undefined) extra.custom_fields = jsonArrayValue(context.args.customFields);
  return context.task(taskId, { ...query, ...Object.fromEntries(Object.entries(extra).filter(([, value]) => value !== undefined)) });
}

async function listTasks(context) {
  const listId = await context.resolveList(listValue(context.args));
  const query = await listTaskQuery(context.args, context);
  return context.client.request('GET', `/list/${pathPart(listId)}/task`, { query });
}

async function saveTask(context) {
  const args = context.args;
  const id = taskValue(args);
  const updating = presentValue(id);
  let listId;
  if (!updating) {
    const list = requireValue(listValue(args), 'Creating a task requires list or listId.');
    listId = await context.resolveList(list);
  }
  const { body, tags } = await buildTaskBody(args, context, updating ? 'update' : 'create');
  const query = await customTaskQuery(args, context);
  if (!updating) return context.client.request('POST', `/list/${pathPart(listId)}/task`, { body });

  const taskId = String(id);
  let result;
  if (Object.keys(body).length) result = await context.client.request('PUT', `/task/${pathPart(taskId)}`, { query, body });
  else if (tags === undefined) throw new ClickUpError('Updating a task requires at least one supported field.', { code: 'invalid_arguments' });
  else result = await context.task(taskId, query);
  if (tags !== undefined) {
    const tagUpdates = await context.syncTaskTags(taskId, tags, query, Object.keys(body).length ? undefined : result);
    return { task: result, tagUpdates };
  }
  return result;
}

async function deleteTask(context) {
  const { taskId, query } = await taskIdAndQuery(context.args, context);
  return context.client.request('DELETE', `/task/${pathPart(taskId)}`, { query });
}

async function getTaskByCustomId(context) {
  const taskId = requireValue(customTaskValue(context.args), 'A custom task ID is required. Use customTaskId, id, task, or taskId.');
  const query = await customTaskQuery(context.args, context, { force: true });
  return context.task(String(taskId), query);
}

async function listTaskComments(context) {
  const { taskId, query } = await taskIdAndQuery(context.args, context);
  const start = aliasValue(context.args, ['start'], 'start');
  const startId = aliasValue(context.args, ['startId'], 'startId');
  if ((start === undefined) !== (startId === undefined)) throw new ClickUpError('Comment pagination requires both start and startId.', { code: 'invalid_arguments' });
  if (start !== undefined) {
    query.start = integerValue(start, 'start');
    query.start_id = requireValue(startId, 'startId');
  }
  return context.client.request('GET', `/task/${pathPart(taskId)}/comment`, { query });
}

async function saveTaskComment(context) {
  const { taskId, query } = await taskIdAndQuery(context.args, context);
  const content = aliasValue(context.args, ['body', 'comment'], 'body/comment');
  requireValue(content, 'save_task_comment requires body or comment.');
  const notifyAll = context.args.notifyAll === undefined ? false : booleanValue(context.args.notifyAll, 'notifyAll');
  const body = { comment_text: String(content), notify_all: notifyAll };
  if (context.args.assignee !== undefined) body.assignee = integerValue(context.args.assignee, 'assignee');
  if (context.args.groupAssignee !== undefined) body.group_assignee = String(context.args.groupAssignee);
  return context.client.request('POST', `/task/${pathPart(taskId)}/comment`, { query, body });
}

async function listTaskTags(context) {
  const spaceId = await context.resolveSpace(spaceValue(context.args));
  return context.client.request('GET', `/space/${pathPart(spaceId)}/tag`, { headers: { 'content-type': 'application/json' } });
}

async function listCustomFields(context) {
  const listId = await context.resolveList(listValue(context.args));
  return context.client.request('GET', `/list/${pathPart(listId)}/field`, {
    query: { include_applied_objects: booleanValue(context.args.includeAppliedObjects, 'includeAppliedObjects') },
    headers: { 'content-type': 'application/json' }
  });
}

async function setCustomFieldValue(context) {
  const { taskId, query } = await taskIdAndQuery(context.args, context);
  const fieldId = requireValue(aliasValue(context.args, ['fieldId', 'field', 'customFieldId'], 'fieldId'), 'set_custom_field_value requires fieldId or field.');
  let body = context.args.body;
  if (body !== undefined) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new ClickUpError('body must be a JSON object for set_custom_field_value.', { code: 'invalid_arguments' });
  } else {
    if (!hasOwn(context.args, 'value')) throw new ClickUpError('set_custom_field_value requires value or body.', { code: 'invalid_arguments' });
    body = { value: context.args.value };
    if (context.args.valueOptions !== undefined) body.value_options = context.args.valueOptions;
  }
  return context.client.request('POST', `/task/${pathPart(taskId)}/field/${pathPart(fieldId)}`, { query, body });
}

const HANDLERS = {
  authenticate: listWorkspaces,
  list_workspaces: listWorkspaces,
  list_spaces: listSpaces,
  list_folders: listFolders,
  list_lists: listLists,
  list_users: listUsers,
  list_task_statuses: listTaskStatuses,
  get_task: getTask,
  list_tasks: listTasks,
  save_task: saveTask,
  delete_task: deleteTask,
  get_task_by_custom_id: getTaskByCustomId,
  list_task_comments: listTaskComments,
  save_task_comment: saveTaskComment,
  list_task_tags: listTaskTags,
  list_custom_fields: listCustomFields,
  set_custom_field_value: setCustomFieldValue
};

function help() {
  return {
    usage: 'clickup.js <command> \'<json-arguments>\'',
    authentication: 'CLICKUP_API_KEY, CLICKUP_TOKEN, or macOS Keychain service "pi ClickUp Skill" account CLICKUP_API_KEY',
    commands: COMMANDS
  };
}

function parseArguments(raw) {
  if (!raw) return {};
  let value;
  try { value = JSON.parse(raw); } catch (error) {
    throw new ClickUpError(`Invalid JSON arguments: ${error.message}`, { code: 'invalid_json' });
  }
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ClickUpError('JSON arguments must be an object.', { code: 'invalid_arguments' });
  }
  return value;
}

async function executeTool(tool, args = {}, dependencies = {}) {
  if (!HANDLERS[tool]) {
    throw new ClickUpError(`Unknown tool: ${tool}. Supported ClickUp tools: ${COMMANDS.join(', ')}.`, { code: 'unknown_tool' });
  }
  const token = getToken(dependencies);
  if (!token) throw new ClickUpError(SETUP_GUIDANCE, { code: 'missing_credentials' });
  const client = new ClickUpClient(token, dependencies);
  const context = new ClickUpContext(args, client);
  try {
    return await HANDLERS[tool](context);
  } catch (error) {
    if (error instanceof ClickUpError) throw error;
    throw new ClickUpError(`ClickUp command failed: ${redact(error?.message || error, token)}`, { code: 'command_error' });
  }
}

async function runCli(argv = process.argv.slice(2), dependencies = {}) {
  const tool = argv[0];
  if (!tool || tool === 'help' || tool === '--help' || tool === '-h') return help();
  const args = parseArguments(argv.slice(1).join(' ').trim());
  return executeTool(tool, args, dependencies);
}

function errorObject(error) {
  const result = { error: error?.message || String(error) };
  if (error?.code) result.code = error.code;
  if (error?.status !== undefined) result.status = error.status;
  if (error?.details !== undefined) result.details = error.details;
  return result;
}

if (require.main === module) {
  runCli().then(result => {
    console.log(JSON.stringify(result, null, 2));
  }).catch(error => {
    console.error(JSON.stringify(errorObject(error), null, 2));
    process.exitCode = 1;
  });
}

module.exports = {
  API_BASE,
  COMMANDS,
  ClickUpClient,
  ClickUpError,
  SETUP_GUIDANCE,
  errorObject,
  executeTool,
  getToken,
  parseArguments,
  runCli,
  toEpochMillis
};
