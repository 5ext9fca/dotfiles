# Configuration Migration Report

## Date

2026-08-17

## Source Configurations Found

- `/Users/hx/.config/ghostty/config.ghostty` — Ghostty — partially migrated.
- `/Users/hx/Library/Application Support/com.mitchellh.ghostty/config.ghostty` — Ghostty — not migrated because the file is empty.
- `/Users/hx/.zshrc` — zsh — partially migrated.
- `/Users/hx/.zprofile` — zsh login profile — migrated.
- `/Users/hx/.zsh_plugins.txt` — Antidote plugin list referenced by zsh — functionality partially migrated through Fish-native features.
- `/Users/hx/.local/bin/env` — environment fragment referenced by zsh — migrated.
- `/Users/hx/.config/zellij/config.kdl` — Zellij — migrated except for one fixed working directory.
- Helix — no source configuration found in the applicable common locations.

## Migrated Items

## WezTerm

- Tokyo Night color scheme.
- Font size 14 on macOS, while retaining the existing cross-platform size 13 default.
- Window background opacity of 0.5.
- macOS background blur with a WezTerm blur radius of 20.
- Initial terminal size of 120 columns by 40 rows.
- Close-without-confirmation behavior.
- The unavailable target font was replaced with WezTerm's bundled JetBrains Mono plus a Nerd Font symbol fallback.
- Existing 8-pixel padding, 10,000-line scrollback, tab-bar behavior, and Windows WSL domain were preserved.

## Fish

- `DOTNET_ROOT` with an installation-directory guard.
- Homebrew environment initialization using Fish syntax.
- User-local, Ruby, mise, rustup, OpenJDK, and Flutter PATH entries with platform/install guards; Homebrew formula and Ruby gem paths are resolved dynamically without pinned versions.
- mise and Starship initialization using Fish syntax and command-availability guards.
- zoxide initialization as the confirmed Fish-compatible replacement for `rupa/z`.
- zsh vi editing behavior through Fish-native vi key bindings.
- Fish-native completion, autosuggestion, syntax-highlighting, and abbreviation capabilities replace the equivalent zsh plugins.
- Existing `EDITOR`, `VISUAL`, `PAGER`, and `MANPAGER` settings were preserved.

## Zellij

- The complete custom keybind mode map, including pane, tab, resize, move, scroll, search, session, tmux, and shared bindings.
- Built-in plugin aliases, background link plugin, welcome screen, and web-client font.
- Existing UI, pane-frame, mouse, scrollback, copy, and session-serialization preferences were preserved.
- Pane viewport serialization was retained using the current `serialize_pane_viewport` option name.
- No layout files were found in the old configuration, so `zellij/layouts/` remains empty.

## Helix

- No old Helix source configuration was available.
- Existing target settings for theme, editor behavior, cursor shapes, indent guides, file picker, statusline, languages, language servers, and auto-format were preserved unchanged.
- The user later removed basedpyright from the Python language-server list; Ruff remains enabled for linting and formatting.

## Ignored Items

See [ignored.md](ignored.md) for the itemized list and reasons.

## Conflicts

- Ghostty font size was 14 globally; the existing WezTerm file used 13 by default and 14 on macOS. Decision: preserve the cross-platform default and keep 14 on macOS, matching the source machine.
- Ghostty requested zsh shell integration, while the target architecture uses Fish. Decision: do not carry over zsh integration; initialize supported tools with Fish syntax instead.
- Existing Fish initialization invoked Starship unconditionally. Decision: preserve Starship but add a command guard so the configuration remains portable when Starship is absent.
- Existing WezTerm configuration requested `FiraCode Nerd Font`, but validation showed that it is not installed. Decision: use bundled JetBrains Mono with `Symbols Nerd Font Mono` fallback for a portable, warning-free configuration.
- Existing Zellij target used `pane_viewport_serialization`; the current source configuration documents `serialize_pane_viewport`. Decision: retain the requested behavior with the current option name.
- The source Zellij file-picker alias forced `cwd "/"`. Decision: preserve the alias without the Unix-only working directory.
- No old Helix configuration existed to compare with the target files. Decision: preserve the target files without inventing migration values.
- The user supplied `101011` for the six pending decisions. Decision: enable macOS blur, keep Zellij auto-start disabled, enable zoxide, remove Ruby/OpenJDK version pins, retain `WSL:Arch`, and accept the existing Helix configuration.

## Remaining Manual Tasks

- None. All six confirmation items were resolved by the user's `101011` decision.

## Installation Scripts

- `install/macos.sh` targets a factory-fresh macOS installation: it requests Xcode Command Line Tools when absent, bootstraps Homebrew with the official installer, installs active dependencies and all four configurations through Homebrew, and changes the login shell to Fish.
- `install/linux.sh` detects and confirms the installed distribution, uses only Pacman, APT, DNF, or Zypper as appropriate, installs no base package manager or general prerequisites, and changes the login shell to Fish.
- `install/windows.ps1` assumes a fresh initialized Arch Linux guest on WSL2, uses WinGet for native WezTerm and Pacman inside Arch for Fish, Zellij, Helix, helpers, and language tooling.
- Windows keeps Helix and Zellij exclusively inside WSL. All installers retain dry-run and conflict-backup behavior.
