# Dotfiles Improvement Tracker

## Critical

- [x] **Exposed OpenAI API key** — Removed from `.zsh_profile`, now sourced from `~/.zsh_secrets`. Key should be revoked and rotated. *(cf20f21)*

## High — Installation flow

- [x] **install.sh is not idempotent** — Running twice appends duplicate NVM lines to `.zshrc`. Added guard check.
- [ ] **Hardcoded username** in `.config/zsh/.zshrc` — `/Users/joaoviegas/.bun/_bun` should use `$HOME`.
- [ ] **Missing TPM bootstrap** — Tmux plugins won't load on fresh install. Add `git clone` for TPM to `install.sh`.
- [ ] **Zap install runs unconditionally** — `zap_zsh.sh` should check if already installed before downloading.
- [ ] **Starship config set AFTER init** — `STARSHIP_CONFIG` export must come before `eval "$(starship init zsh)"` in `.zshrc`.

## Medium — Config correctness

- [ ] **Duplicate PATH entries** in `.zshrc` — `~/.local/bin` added twice, multiple PATH modifications scattered. Consolidate into single block.
- [ ] **No error handling** in `install.sh` — Add tool existence checks for `fzf`, `zoxide`, `starship`, `JAVA_HOME`.
- [ ] **Hardcoded Android SDK path** in `.local/bin/android-emulator.sh` — Should use `$ANDROID_SDK_ROOT` or default to `~/Library/Android/sdk`.
- [ ] **Outdated `.exports` file** — Has stale NVM config, seems unused by current zsh setup.
- [ ] **`start-to-work.sh` references missing apps** — Arc and Inkdrop not in `cask.sh`.

## Low — Cleanup

- [ ] **Verify `.zsh_profile` source path** — `.zshrc` sources `$HOME/.zsh_profile` but file lives at `$HOME/.config/zsh/.zsh_profile` after copy.
- [ ] **`de-config/` contains Linux-only dconf settings** — Irrelevant on macOS, consider removing.
- [ ] **Company install script is incomplete** — No dotfile copy, no nvim symlink. Either complete or document limitations.
