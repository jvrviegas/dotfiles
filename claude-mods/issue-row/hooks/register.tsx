import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Issue, Pr } from '../types'
import { issueKey, parseIssue, parsePr, segments } from './issue'

const row = atom({ plugin: 'issue-row', key: 'row' } as const, null)

const LINEAR = 'claude.ai Linear'
const POLL_MS = 3 * 60_000
// After a turn, refetch only when the branch changed or the row is older than this.
const STALE_MS = 60_000
// At startup the Linear connector is still connecting: retry this often, this many times.
const RETRY_MS = 10_000
const RETRIES = 6

async function fetchIssue($: EngineInterface, key: string): Promise<{ issue: Issue | null; isMissing: boolean }> {
  try {
    const result = await $.mcp.call(LINEAR, 'get_issue', {
      id: key,
      fields: ['title', 'status', 'statusType', 'assignee', 'url'],
    })
    const text = result.content.map(block => block.text ?? '').join('')
    if (result.isError) {
      return { issue: null, isMissing: /could not find/i.test(text) }
    }

    return { issue: parseIssue(key, text), isMissing: false }
  } catch {
    return { issue: null, isMissing: false }
  }
}

async function fetchPr($: EngineInterface): Promise<{ pr: Pr | null; prNote: string | null }> {
  const ran = await $.process
    .run(['gh', 'pr', 'view', '--json', 'number,url,state,isDraft,reviewDecision,statusCheckRollup'])
    .catch(() => null)
  if (ran?.exitCode === 0) {
    return { pr: parsePr(ran.stdout), prNote: null }
  }
  // The repo exists but the active gh account cannot see it.
  if (ran !== null && /could not resolve to a repository/i.test(ran.stderr)) {
    return { pr: null, prNote: 'PR unknown: active gh account has no access' }
  }

  return { pr: null, prNote: null }
}

let key: string | null = null
let fetchedAt = 0
let isRefreshing = false
let retries = 0
const missing = new Set<string>()

async function refresh($: EngineInterface, isForced: boolean) {
  if (isRefreshing) {
    return
  }
  isRefreshing = true
  try {
    const git = await $.process.run(['git', 'rev-parse', '--show-toplevel', '--abbrev-ref', 'HEAD']).catch(() => null)
    const [top = '', branch = ''] = git?.exitCode === 0 ? git.stdout.trim().split('\n') : []
    const found = issueKey(branch, top.split('/').pop() ?? '')
    const now = await $.clock.now()
    if (found === key && !isForced && now - fetchedAt < STALE_MS) {
      return
    }
    key = found
    fetchedAt = now
    if (found === null || missing.has(found)) {
      await update($, row, () => null)
      return
    }

    const [{ issue, isMissing }, { pr, prNote }] = await Promise.all([fetchIssue($, found), fetchPr($)])
    if (isMissing) {
      missing.add(found)
    }
    if (issue !== null) {
      retries = 0
    } else if (!isMissing && retries < RETRIES) {
      retries += 1
      fetchedAt = 0
      $.clock.after(RETRY_MS, () => void refresh($, true))
    }
    await update($, row, previous => {
      if (issue !== null) {
        return { issue, pr, prNote }
      }
      // Keep the last row through a failed fetch of the same issue.
      return !isMissing && previous?.issue.key === found ? previous : null
    })
  } finally {
    isRefreshing = false
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    $.clock.after(0, () => void refresh($, true))
    $.clock.every(POLL_MS, () => void refresh($, true))

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    $.clock.after(0, () => void refresh($, false))

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const current = await read($, row)
    if (e.props.hasSurvey || current === null) {
      return next(e)
    }

    const { Text } = $.ui.resolve(e)

    return (
      <Text wrap="truncate-end">
        {segments(current, e.props.bodyColumns).map(part => (
          <Text
            {...(part.color !== undefined && { color: part.color })}
            {...(part.isBold && { bold: true })}
            {...(part.isDim && { dimColor: true })}
          >
            {part.text}
          </Text>
        ))}
      </Text>
    )
  })
}
