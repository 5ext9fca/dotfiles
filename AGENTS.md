# Repository Guidelines

## Project Structure & Module Organization

This repository stores configuration by application. `fish/`, `helix/`, `wezterm/`, and `zellij/` mirror the directories linked into the user's configuration home. Keep application-specific files inside their existing directory; for example, add Fish startup fragments under `fish/conf.d/` with a numeric prefix such as `30-aliases.fish`. Platform bootstrap scripts live in `install/`, and `install/README.md` documents their supported environments and side effects. Root-level Markdown files contain migration and maintenance notes.

## Build, Test, and Development Commands

There is no build step or centralized test suite. Validate changes with the platform installer's non-mutating mode:

- `./install/macos.sh --dry-run` checks the macOS workflow and prints planned actions.
- `./install/linux.sh --dry-run` detects the Linux distribution and prompts for confirmation.
- `./install/linux.sh --dry-run --yes` is suitable for non-interactive Linux validation.
- `.\install\windows.ps1 -DryRun` validates the Windows/Arch WSL workflow from PowerShell.

When available, run `shellcheck install/*.sh` for Bash changes. Parse configuration with its owning tool, such as `fish -n fish/config.fish`, `wezterm ls-fonts`, or `hx --health`.

## Coding Style & Naming Conventions

Preserve each format's native conventions: two-space indentation for Lua, four spaces for PowerShell, and readable TOML/KDL formatting. Bash scripts use `#!/usr/bin/env bash`, `set -euo pipefail`, lowercase `snake_case` variables/functions, and quoted expansions. PowerShell uses PascalCase for functions and parameters. Keep configuration declarative and platform checks explicit; do not embed machine-specific absolute paths or secrets.

## Testing Guidelines

Treat dry runs as the minimum regression check for installer edits. Test only on the relevant operating system, and verify that repeated runs are idempotent: existing correct links should remain untouched, while conflicting files should be backed up. For configuration edits, launch or parse the affected application and record the validation performed in the pull request.

## Commit & Pull Request Guidelines

The repository has no commit history, so no established message convention exists. Use short, imperative subjects such as `Add Fedora package mapping` and keep each commit focused. Pull requests should describe affected platforms and applications, list commands run, and call out package, login-shell, symlink, or backup behavior changes. Include screenshots only for visible terminal or editor changes, and link related issues when applicable.

## Security & Configuration Tips

Never commit credentials, tokens, host-specific identifiers, or private environment values. Preserve dry-run support for privileged and destructive operations, and keep backup behavior intact when changing link targets.
