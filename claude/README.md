# Claude Code configuration

Portable Claude Code configuration tracked by this dotfiles repository lives in
this directory. Running `source install.sh` copies the settings, global
instructions, commands, hooks, skills, themes, notification script, and
statusline files to `~/.claude/`.

Shared cross-agent skill sources are stored under `agent-skills/` and copied to
`~/.agents/skills/`. Keeping the tracked source outside `.agents/skills/` avoids
Pi loading both project and global copies. Relative symlinks in `claude/skills/`
resolve to the tracked source.

Credentials, local settings, projects, sessions, history, caches, plugin
installations, generated skill dependencies, and other runtime data are not
tracked. Authenticate and install any required Claude Code plugins separately
on each computer.
