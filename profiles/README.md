# Deployment profiles

Each profile is an adapter used by the top-level `install` interface.

A profile provides `profile.sh` with three functions:

```bash
profile_preflight
profile_install_packages
profile_install_config
```

Its `home/` directory is an overlay whose paths are relative to `$HOME`.
Shared configuration lives in `home/common/` at the repository root.

Supported profiles:

- `macos`
- `fedora-gnome`
- `omarchy`

Do not add package-manager or desktop-specific branching to `lib/deploy.sh`.
Keep that implementation in the relevant profile adapter.
