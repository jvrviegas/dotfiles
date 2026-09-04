# Claude Code configuration

Portable Claude Code configuration tracked by this dotfiles repository lives in
this directory. Running `source install.sh` copies the settings, global
instructions, commands, hooks, skills, themes, notification script, and
statusline files to `~/.claude/`.

Shared cross-agent skills are stored under `.agents/skills/` and copied to
`~/.agents/skills/`. Relative symlinks in `claude/skills/` continue to resolve
there.

Credentials, local settings, projects, sessions, history, caches, plugin
installations, generated skill dependencies, and other runtime data are not
tracked. Authenticate and install any required Claude Code plugins separately
on each computer.
