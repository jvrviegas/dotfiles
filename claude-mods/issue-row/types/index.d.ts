export type Issue = {
  key: string
  title: string
  status: string
  statusType: string
  assignee: string | null
  url: string
}

export type Checks = 'passed' | 'failed' | 'running' | 'none'

export type Pr = {
  number: number
  url: string
  state: string
  isDraft: boolean
  review: string
  checks: Checks
}

export type Row = {
  issue: Issue
  pr: Pr | null
  prNote: string | null
}

export type Segment = {
  text: string
  color?: string
  isBold?: boolean
  isDim?: boolean
}

declare module 'claude-code' {
  interface PluginState {
    'issue-row': { row: Row | null }
  }
}
