import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { issueKey, segments, summarizeChecks } from '../hooks/issue'

const ISSUE = {
  id: 'PRO-1691',
  title: 'Show live machine states on the machines page',
  status: 'In Review',
  statusType: 'started',
  assignee: 'João Viegas',
  url: 'https://linear.app/procimo/issue/PRO-1691',
}

const PR = {
  number: 44,
  url: 'https://github.com/Procimo/plastaze-mes/pull/44',
  state: 'OPEN',
  isDraft: false,
  reviewDecision: 'CHANGES_REQUESTED',
  statusCheckRollup: [{ status: 'COMPLETED', conclusion: 'FAILURE' }],
}

const ROW_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 10,
  bodyColumns: 120,
  scroll: { offset: 0, bodyRows: 10 },
  view: {},
}

function ran(stdout: string, exitCode = 0, stderr = '') {
  return { exitCode, stdout, stderr, isStdoutTruncated: false, isStderrTruncated: false }
}

/**
 * Stubs git, gh and Linear beneath the plugin, as a session in that worktree would answer;
 * Linear refuses its first `linearDownCalls` calls, as while its connector is still connecting.
 */
function stubSession(on: On, git: { top: string; branch: string }, gh = ran(JSON.stringify(PR)), linearDownCalls = 0) {
  let linearCalls = 0
  on('session.start', () => ({ cwd: git.top }))
  on('process.run', ($, e) => ({ value: e.argv[0] === 'git' ? ran(`${git.top}\n${git.branch}\n`) : gh }))
  on('mcp.call', ($, e) => {
    linearCalls += 1
    if (linearCalls <= linearDownCalls) {
      return { deny: 'no connected MCP tool "get_issue" on a server named "claude.ai Linear"' }
    }
    const isKnown = e.args.id === ISSUE.id

    return {
      value: {
        content: [{ type: 'text', text: isKnown ? JSON.stringify(ISSUE) : 'Could not find referenced Issue.' }],
        isError: !isKnown,
      },
    }
  })
  // The engine's own band: nothing to show.
  on('ui.render', () => ({ type: 'Box', props: {}, children: [] }))
}

test('finds the key in the branch, then the worktree folder', () => {
  expect(issueKey('pro-1720-fix-team-calendar', 'procimo-internal')).toBe('PRO-1720')
  expect(issueKey('feature/DEV2-1439-gantt', '')).toBe('DEV2-1439')
  expect(issueKey('cp-389-local-run', '')).toBe('CP-389')
  expect(issueKey('main', 'plastaze-mes-pro-1691-shopfloor')).toBe('PRO-1691')
  expect(issueKey('fix/dev-functions-cpu', 'procimo-smartops')).toBe(null)
})

test('sums up the checks', () => {
  expect(summarizeChecks([])).toBe('none')
  expect(summarizeChecks([{ status: 'COMPLETED', conclusion: 'SUCCESS' }, { state: 'SUCCESS' }])).toBe('passed')
  expect(summarizeChecks([{ status: 'IN_PROGRESS', conclusion: '' }])).toBe('running')
  expect(summarizeChecks([{ state: 'PENDING' }, { status: 'COMPLETED', conclusion: 'FAILURE' }])).toBe('failed')
})

test('cuts the title, never the status or PR', () => {
  const issue = { key: 'PRO-1', title: 'x'.repeat(200), status: 'Todo', statusType: 'unstarted', assignee: null, url: '' }
  const text = segments({ issue, pr: null, prNote: null }, 40).map(part => part.text).join('')
  expect(text.length).toBe(40)
  expect(text.endsWith('… · Todo')).toBe(true)
})

for (const surface of ['terminal', 'desktop'] as const) {
  test(`draws the branch's issue with its PR on ${surface}`, async ($, on) => {
    const clock = mock.clock(on)
    stubSession(on, { top: '/p/plastaze-mes-pro-1691', branch: 'pro-1691-live-states' })

    await $.session.start({ cwd: '/p/plastaze-mes-pro-1691', surface, isInteractive: true })
    await clock.settle()

    const ui = await $.ui.mount({ plugin: 'issue-row', surface, component: 'AbovePrompt', props: ROW_PROPS })
    const row = await ui.find({ type: 'Text' })
    expect(row?.text).toContain('PRO-1691 Show live machine states on the machines page')
    expect(row?.text).toContain('In Review · João Viegas · PR #44 changes requested · CI ✗')
  })

  test(`draws nothing on a branch with no Linear issue on ${surface}`, async ($, on) => {
    const clock = mock.clock(on)
    stubSession(on, { top: '/p/procimo-internal', branch: 'node-18-upgrade' })

    await $.session.start({ cwd: '/p/procimo-internal', surface, isInteractive: true })
    await clock.settle()

    const ui = await $.ui.mount({ plugin: 'issue-row', surface, component: 'AbovePrompt', props: ROW_PROPS })
    expect(await ui.find({ type: 'Text' })).toBe(undefined)
  })
}

test('says when the active gh account cannot see the repo', async ($, on) => {
  const clock = mock.clock(on)
  stubSession(
    on,
    { top: '/p/procimo-internal', branch: 'pro-1691-live-states' },
    ran('', 1, "GraphQL: Could not resolve to a Repository with the name 'Procimo/procimo-internal'."),
  )

  await $.session.start({ cwd: '/p/procimo-internal', surface: 'terminal', isInteractive: true })
  await clock.settle()

  const ui = await $.ui.mount({ plugin: 'issue-row', surface: 'terminal', component: 'AbovePrompt', props: ROW_PROPS })
  expect((await ui.find({ type: 'Text' }))?.text).toContain('PR unknown: active gh account has no access')
})

test('retries Linear while its connector is still connecting at startup', async ($, on) => {
  const clock = mock.clock(on)
  stubSession(on, { top: '/p/plastaze-mes-pro-1691', branch: 'pro-1691-live-states' }, ran(JSON.stringify(PR)), 1)

  await $.session.start({ cwd: '/p/plastaze-mes-pro-1691', surface: 'terminal', isInteractive: true })
  await clock.settle()
  const ui = await $.ui.mount({ plugin: 'issue-row', surface: 'terminal', component: 'AbovePrompt', props: ROW_PROPS })
  expect(await ui.find({ type: 'Text' })).toBe(undefined)

  await clock.advance(10_000)
  expect((await ui.find({ type: 'Text' }))?.text).toContain('PRO-1691 Show live machine states')
})
