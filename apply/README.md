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

On Windows, run the PowerShell apply script from the repository to synchronize
the Windows Terminal configuration:

```powershell
.\apply\windows.ps1 -DryRun
.\apply\windows.ps1
```

Windows uses a content-checked copy because links to a repository exposed
through a WSL UNC path are not reliably available. If `settings.json` differs,
the existing Windows Terminal settings file is moved under
`${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backups/<timestamp>}` before the new
copy is written. Re-running the script leaves an identical copy untouched.
