const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ClickUpError,
  executeTool,
  getToken,
  runCli
} = require('../scripts/clickup.js');

const TOKEN = 'pk_test_secret_should_not_leak';

function jsonResponse(status, body, headers = {}) {
  return {
    status,
    ok: status >= 200 && status < 300,
    statusText: status === 200 ? 'OK' : 'Error',
    headers: {
      get(name) {
        const key = Object.keys(headers).find(candidate => candidate.toLowerCase() === name.toLowerCase());
        return key ? headers[key] : null;
      }
    },
    async text() {
      return body === undefined ? '' : JSON.stringify(body);
    }
  };
}

function dependency(fetch, overrides = {}) {
  return {
    env: { CLICKUP_API_KEY: TOKEN },
    platform: 'linux',
    fetch,
    sleep: async () => {},
    ...overrides
  };
}

test('API key takes precedence over token', () => {
  assert.equal(getToken({
    env: { CLICKUP_API_KEY: 'api-key', CLICKUP_TOKEN: 'token' },
    platform: 'linux'
  }), 'api-key');
});

test('token works when API key is absent', () => {
  assert.equal(getToken({
    env: { CLICKUP_TOKEN: 'token' },
    platform: 'linux'
  }), 'token');
});

test('Keychain is used only when environment variables are absent', () => {
  let calls = 0;
  const run = () => {
    calls += 1;
    return 'keychain-token\n';
  };
  assert.equal(getToken({ env: {}, platform: 'darwin', execFileSync: run }), 'keychain-token');
  assert.equal(calls, 1);
  assert.equal(getToken({ env: { CLICKUP_TOKEN: 'env-token' }, platform: 'darwin', execFileSync: () => {
    throw new Error('Keychain should not be called');
  } }), 'env-token');
});

test('Keychain lookup uses the ClickUp service and account', () => {
  let call;
  getToken({
    env: {},
    platform: 'darwin',
    execFileSync(...args) {
      call = args;
      return 'pk-keychain';
    }
  });
  assert.deepEqual(call.slice(0, 2), ['security', [
    'find-generic-password',
    '-s', 'pi ClickUp Skill',
    '-a', 'CLICKUP_API_KEY',
    '-w'
  ]]);
});

test('personal-token Authorization header has no Bearer prefix', async () => {
  let request;
  const result = await executeTool('list_workspaces', {}, dependency(async (url, options) => {
    request = { url, options };
    return jsonResponse(200, { teams: [] });
  }));
  assert.deepEqual(result, { teams: [] });
  assert.equal(request.options.headers.Authorization, TOKEN);
  assert.notEqual(request.options.headers.Authorization, `Bearer ${TOKEN}`);
  assert.equal(new URL(request.url).pathname, '/api/v2/team');
});

test('invalid JSON arguments produce a structured error', async () => {
  await assert.rejects(
    runCli(['list_workspaces', '{not-json'], dependency(async () => jsonResponse(200, {}))),
    error => error instanceof ClickUpError && error.code === 'invalid_json' && /Invalid JSON arguments/.test(error.message)
  );
});

test('task creation rejects missing List context before making a request', async () => {
  let calls = 0;
  await assert.rejects(
    executeTool('save_task', { title: 'No list' }, dependency(async () => {
      calls += 1;
      return jsonResponse(500, { err: 'must not be called' });
    })),
    error => error.code === 'invalid_arguments' && /requires list or listId/.test(error.message)
  );
  assert.equal(calls, 0);
});

test('title maps to ClickUp name on task creation', async () => {
  let request;
  await executeTool('save_task', { list: '123', title: 'Mapped title', dueDate: '2026-01-02T03:04:05Z' }, dependency(async (url, options) => {
    request = { url, options };
    return jsonResponse(200, { id: 'task-1', name: 'Mapped title' });
  }));
  assert.equal(new URL(request.url).pathname, '/api/v2/list/123/task');
  assert.equal(request.options.method, 'POST');
  assert.deepEqual(JSON.parse(request.options.body), {
    name: 'Mapped title',
    due_date: Date.parse('2026-01-02T03:04:05Z')
  });
});

test('task update sends PUT /task/{id}', async () => {
  let request;
  await executeTool('save_task', { id: 'task-42', description: 'Updated' }, dependency(async (url, options) => {
    request = { url, options };
    return jsonResponse(200, { id: 'task-42', description: 'Updated' });
  }));
  assert.equal(request.options.method, 'PUT');
  assert.equal(new URL(request.url).pathname, '/api/v2/task/task-42');
  assert.deepEqual(JSON.parse(request.options.body), { description: 'Updated' });
});

test('custom task IDs use ClickUp custom-task query parameters', async () => {
  let request;
  await executeTool('get_task_by_custom_id', { customTaskId: 'CU-42', teamId: '123' }, dependency(async (url, options) => {
    request = { url, options };
    return jsonResponse(200, { id: 'CU-42' });
  }));
  const parsed = new URL(request.url);
  assert.equal(parsed.pathname, '/api/v2/task/CU-42');
  assert.equal(parsed.searchParams.get('custom_task_ids'), 'true');
  assert.equal(parsed.searchParams.get('team_id'), '123');
});

test('errors never expose tokens', async () => {
  let thrown;
  try {
    await executeTool('list_workspaces', {}, dependency(async () => jsonResponse(401, { err: `invalid token ${TOKEN}` })));
  } catch (error) {
    thrown = error;
  }
  assert.ok(thrown);
  assert.doesNotMatch(thrown.message, new RegExp(TOKEN));
  assert.doesNotMatch(JSON.stringify(thrown), new RegExp(TOKEN));
});

test('429 response retries once and honors Retry-After', async () => {
  let calls = 0;
  const delays = [];
  const result = await executeTool('list_workspaces', {}, dependency(async () => {
    calls += 1;
    return calls === 1
      ? jsonResponse(429, { err: 'rate limited' }, { 'Retry-After': '0' })
      : jsonResponse(200, { teams: [{ id: '1' }] });
  }, { sleep: async milliseconds => delays.push(milliseconds) }));
  assert.deepEqual(result, { teams: [{ id: '1' }] });
  assert.equal(calls, 2);
  assert.deepEqual(delays, [0]);
});

test('429 response is not retried more than once', async () => {
  let calls = 0;
  await assert.rejects(
    executeTool('list_workspaces', {}, dependency(async () => {
      calls += 1;
      return jsonResponse(429, { message: 'rate limited' }, { 'Retry-After': '0' });
    })),
    error => error.status === 429
  );
  assert.equal(calls, 2);
});

test('status lookup allows parent scope for a named Folder', async () => {
  const requests = [];
  const result = await executeTool('list_task_statuses', { folder: 'Roadmap', space: '456' }, dependency(async url => {
    requests.push(url);
    if (url.endsWith('/space/456/folder')) return jsonResponse(200, { folders: [{ id: '789', name: 'Roadmap' }] });
    return jsonResponse(200, { statuses: [{ status: 'open' }] });
  }));
  assert.deepEqual(result.statuses, [{ status: 'open' }]);
  assert.equal(new URL(requests.at(-1)).pathname, '/api/v2/folder/789');
});

test('ambiguous resolver result fails with candidates', async () => {
  await assert.rejects(
    executeTool('list_lists', { folder: '456', list: 'Backlog' }, dependency(async url => {
      assert.equal(new URL(url).pathname, '/api/v2/folder/456/list');
      return jsonResponse(200, { lists: [
        { id: 'list-1', name: 'Backlog' },
        { id: 'list-2', name: 'Backlog' }
      ] });
    })),
    error => error.code === 'ambiguous_resource' && error.details.candidates.length === 2 && /list-1/.test(error.message)
  );
});

test('unknown tool returns an actionable error', async () => {
  await assert.rejects(
    executeTool('not_a_clickup_tool', {}, dependency(async () => jsonResponse(200, {}))),
    error => error.code === 'unknown_tool' && /Supported ClickUp tools/.test(error.message)
  );
});

test('task tags use ClickUp tag endpoints when updating', async () => {
  const requests = [];
  const result = await executeTool('save_task', { id: 'task-1', tags: ['urgent'] }, dependency(async (url, options) => {
    requests.push({ url, options });
    if (requests.length === 1) return jsonResponse(200, { id: 'task-1', tags: [{ name: 'old' }] });
    if (requests.length === 2) return jsonResponse(200, {});
    return jsonResponse(200, { id: 'task-1', tags: [{ name: 'urgent' }] });
  }));
  assert.equal(requests[0].options.method, 'GET');
  assert.equal(requests[1].options.method, 'DELETE');
  assert.equal(new URL(requests[1].url).pathname, '/api/v2/task/task-1/tag/old');
  assert.equal(requests[2].options.method, 'POST');
  assert.equal(new URL(requests[2].url).pathname, '/api/v2/task/task-1/tag/urgent');
  assert.deepEqual(result.tagUpdates, { added: ['urgent'], removed: ['old'] });
});
