# Apply configuration updates

`apply.sh` refreshes the local WezTerm, Fish, Zellij, and Helix configuration
after this repository is updated. It recursively creates hard links for regular
files under `${XDG_CONFIG_HOME:-$HOME/.config}`.

```sh
./apply/apply.sh --dry-run
./apply/apply.sh
./apply/apply.sh fish helix
```

The repository and local configuration directory must be on the same
filesystem because hard links cannot cross filesystem boundaries. Existing
targets that are not already the correct hard links are moved under
`${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backups/<timestamp>}` before they are
replaced. Re-running the script leaves correct hard links untouched.
Optional component arguments restrict application to `wezterm`, `fish`,
`zellij`, and/or `helix`; without arguments all four are applied.
