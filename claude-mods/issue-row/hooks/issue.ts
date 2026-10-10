import type { Checks, Issue, Pr, Row, Segment } from '../types'

// A Linear key as branch and folder names spell it: pro-1691, cp-389, dev2-1439.
const KEY = /(?:^|[^a-z0-9])([a-z][a-z0-9]{1,6})-(\d{1,6})(?![0-9])/i

const FAILED = new Set(['FAILURE', 'ERROR', 'TIMED_OUT', 'CANCELLED', 'ACTION_REQUIRED', 'STARTUP_FAILURE'])

const STATUS_COLOR: Record<string, string> = {
  triage: 'permission',
  started: 'warning',
  completed: 'success',
  canceled: 'inactive',
}

const SEPARATOR: Segment = { text: ' · ', isDim: true }

type Check = { status?: string; conclusion?: string; state?: string }

/** The first issue key in the names given, in order (branch first, then folder). */
export function issueKey(...names: string[]): string | null {
  for (const name of names) {
    const [, team, number] = KEY.exec(name) ?? []
    if (team !== undefined && number !== undefined) {
      return `${team.toUpperCase()}-${number}`
    }
  }

  return null
}

/** Linear's get_issue text, as asked for with the fields title, status, statusType, assignee, url. */
export function parseIssue(key: string, text: string): Issue | null {
  try {
    const json = JSON.parse(text)
    if (typeof json.title !== 'string') {
      return null
    }

    return {
      key,
      title: json.title,
      status: String(json.status ?? ''),
      statusType: String(json.statusType ?? ''),
      assignee: typeof json.assignee === 'string' ? json.assignee : null,
      url: String(json.url ?? ''),
    }
  } catch {
    return null
  }
}

/** CheckRuns carry status and conclusion; StatusContexts carry state. */
export function summarizeChecks(rollup: readonly Check[]): Checks {
  if (rollup.length === 0) {
    return 'none'
  }
  if (rollup.some(check => FAILED.has(check.conclusion || check.state || ''))) {
    return 'failed'
  }
  const isRunning = rollup.some(
    check =>
      (check.status !== undefined && check.status !== 'COMPLETED') ||
      check.state === 'PENDING' ||
      check.state === 'EXPECTED',
  )

  return isRunning ? 'running' : 'passed'
}

/** `gh pr view --json number,url,state,isDraft,reviewDecision,statusCheckRollup` output. */
export function parsePr(text: string): Pr | null {
  try {
    const json = JSON.parse(text)

    return {
      number: json.number,
      url: json.url,
      state: json.state,
      isDraft: json.isDraft === true,
      review: json.reviewDecision ?? '',
      checks: summarizeChecks(json.statusCheckRollup ?? []),
    }
  } catch {
    return null
  }
}

function prSegment(pr: Pr): Segment {
  const name = `PR #${pr.number}`
  if (pr.state === 'MERGED') {
    return { text: `${name} merged`, color: 'merged' }
  }
  if (pr.state === 'CLOSED') {
    return { text: `${name} closed`, color: 'inactive' }
  }
  if (pr.isDraft) {
    return { text: `${name} draft`, color: 'subtle' }
  }
  if (pr.review === 'APPROVED') {
    return { text: `${name} approved`, color: 'success' }
  }
  if (pr.review === 'CHANGES_REQUESTED') {
    return { text: `${name} changes requested`, color: 'error' }
  }
  if (pr.review === 'REVIEW_REQUIRED') {
    return { text: `${name} awaiting review`, color: 'warning' }
  }

  return { text: `${name} open` }
}

function ciSegment(checks: Checks): Segment | null {
  if (checks === 'passed') {
    return { text: 'CI ✓', color: 'success' }
  }
  if (checks === 'failed') {
    return { text: 'CI ✗', color: 'error' }
  }
  if (checks === 'running') {
    return { text: 'CI …', color: 'warning' }
  }

  return null
}

/** The row as colored pieces, the title cut so the rest fits in `columns`. */
export function segments(row: Row, columns: number): Segment[] {
  const { issue, pr, prNote } = row
  const tail: Segment[] = [
    SEPARATOR,
    { text: issue.status, color: STATUS_COLOR[issue.statusType] ?? 'subtle' },
  ]
  if (issue.assignee !== null) {
    tail.push(SEPARATOR, { text: issue.assignee, isDim: true })
  }
  if (pr !== null) {
    tail.push(SEPARATOR, prSegment(pr))
    const ci = ciSegment(pr.checks)
    if (ci !== null) {
      tail.push(SEPARATOR, ci)
    }
  } else if (prNote !== null) {
    tail.push(SEPARATOR, { text: prNote, isDim: true })
  }

  const key: Segment = { text: `${issue.key} `, color: 'suggestion', isBold: true }
  const used = [key, ...tail].reduce((sum, part) => sum + part.text.length, 0)
  const room = Math.max(8, columns - used)
  const title = issue.title.length > room ? `${issue.title.slice(0, room - 1)}…` : issue.title

  return [key, { text: title }, ...tail]
}
