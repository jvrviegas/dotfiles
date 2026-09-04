# Pi configuration

Portable global Pi configuration tracked by this dotfiles repository lives in
`.pi/agent/`. Running `source install.sh` copies these resources to
`~/.pi/agent/`:

- `settings.json`
- `AGENTS.md`, `SYSTEM.md`, and `APPEND_SYSTEM.md` when present
- `extensions/`
- `prompts/`
- `skills/`
- `themes/`

Runtime data and credentials are intentionally not tracked. Authenticate on
each computer with `pi` and `/login`. The root `.gitignore` excludes Pi auth,
OAuth data, sessions, trust decisions, model caches, and installed package
folders.
