# Ignored Configuration

## `/Users/hx/.config/ghostty/config.ghostty`

### Items

- `background-opacity-cells = true`
- `notify-on-command-finish = unfocused`
- `shell-integration = zsh`

### Reasons

- The cell-opacity switch has no separate WezTerm equivalent; the overall opacity was migrated.
- The command-finished notification policy has no native WezTerm configuration equivalent.
- zsh shell integration conflicts with the Fish target architecture. WezTerm shell integration is negotiated by the shell, while Fish tool initialization is configured separately.

## `/Users/hx/Library/Application Support/com.mitchellh.ghostty/config.ghostty`

### Items

- Empty fallback configuration file.

### Reasons

- It contains no settings to migrate.

## `/Users/hx/.zshrc`

### Items

- zsh history variables and `setopt` directives.
- Antidote loader commands.
- `eval "$(zellij setup --generate-auto-start zsh)"` restricted to Ghostty.

### Reasons

- The history directives are zsh-specific; Fish manages persistent history natively and has no exact mapping for every option.
- Antidote is a zsh plugin manager and cannot be loaded by Fish.
- The Zellij auto-start condition is tied to both Ghostty and zsh. The user confirmed that Zellij should not auto-start under WezTerm/Fish.

## `/Users/hx/.zsh_plugins.txt`

### Items

- `jeffreytse/zsh-vi-mode`, `olets/zsh-abbr`, completion plugins, autosuggestions, syntax highlighting, and history-substring-search packages.
- `romkatv/zsh-bench` and `mattmc3/zfunctions`.

### Reasons

- These packages use zsh-specific loading or completion mechanisms. Fish natively supplies vi bindings, abbreviations, completions, autosuggestions, and syntax highlighting; the corresponding behavior was used instead of migrating packages.
- The benchmark and helper-function packages are zsh-specific and have no direct Fish configuration mapping.

## `/Users/hx/.config/zellij/config.kdl`

### Items

- File-picker plugin working directory `cwd "/"`.

### Reasons

- It binds the configuration to a Unix root path and conflicts with the cross-platform target. The file-picker plugin alias was migrated without a fixed working directory.

## Helix search locations

### Items

- No source Helix configuration was found in `/Users/hx/.config/helix/` or the other applicable common locations.

### Reasons

- There was no old Helix configuration to migrate. Existing files under `dotfiles/helix/` were preserved as the new structure.
