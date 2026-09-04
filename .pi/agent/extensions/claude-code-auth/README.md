# pi Claude Code Auth

Registers a `claude-code` provider in pi that uses local Claude Code OAuth credentials instead of an Anthropic API key.

## Prerequisites

1. Install and authenticate Claude Code.
2. Run `claude` once so credentials exist in the macOS Keychain or `~/.claude/.credentials.json`.

## Usage

Restart pi, then select one of:

- `claude-code/claude-sonnet-4-5`
- `claude-code/claude-opus-4-5`
- `claude-code/claude-haiku-4-5`

Optional environment variables:

- `CLAUDE_CODE_ACCOUNT_SOURCE` — Keychain service name to select a specific account, e.g. `Claude Code-credentials`.
- `ANTHROPIC_CLI_VERSION` — Claude CLI version used in billing/user-agent headers.
- `ANTHROPIC_USER_AGENT` — full User-Agent override.
- `ANTHROPIC_BETA_FLAGS` — beta flags override. Do not add long-context betas unless you want extra usage behavior.

## Notes

This intentionally does not enable 1M context. Context windows are capped at 200k to avoid long-context extra usage.

This is an unofficial compatibility provider. It may break if Anthropic changes Claude Code OAuth or billing validation.
