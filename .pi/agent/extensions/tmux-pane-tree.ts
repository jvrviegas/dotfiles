import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { homedir } from 'node:os'
import { join } from 'node:path'

const hook = join(homedir(), '.config', 'tmux', 'plugins', 'tmux-pane-tree', 'scripts', 'features', 'hooks', 'hook-pi.sh')

function pickMessage(event: unknown): string {
  if (!event || typeof event !== 'object') {
    return ''
  }

  const record = event as Record<string, unknown>
  for (const key of ['message', 'summary', 'prompt', 'toolName', 'tool_name']) {
    const value = record[key]
    if (typeof value === 'string' && value.trim()) {
      return value.trim()
    }
  }
  return ''
}

async function emit(pi: ExtensionAPI, eventName: string, event: unknown): Promise<void> {
  const payload = JSON.stringify({
    event: eventName,
    message: pickMessage(event),
  })
  try {
    await pi.exec('bash', [hook, payload])
  } catch {
    // Hook failures should not break the agent session.
  }
}

export default function (pi: ExtensionAPI) {
  pi.on('session_start', async (event) => emit(pi, 'session_start', event))
  pi.on('session_shutdown', async (event) => emit(pi, 'session_shutdown', event))
  pi.on('agent_start', async (event) => emit(pi, 'agent_start', event))
  pi.on('agent_end', async (event) => emit(pi, 'agent_end', event))
  pi.on('turn_start', async (event) => emit(pi, 'turn_start', event))
  pi.on('tool_call', async (event) => emit(pi, 'tool_call', event))
}
