# Dotfiles Installers

Each platform has one explicit preset and uses only its applicable system package manager. The installers deploy the configurations and change the login shell to Fish.

Active dependencies include WezTerm, Fish, Zellij, Helix, Starship, mise, zoxide, Ruff, and the Rust/C/C++ language tools used by Helix. Ruby, OpenJDK, .NET, and Flutter remain optional and are not installed.

Existing configuration targets are moved into a timestamped directory under `~/.dotfiles-backups/` before links are created. Changing the login shell may ask for a password.

## macOS preset

Baseline: a factory-fresh macOS installation. No preinstalled Homebrew or developer tools are assumed.

Bootstrap and package management:

- macOS installs Xcode Command Line Tools through the system-provided `xcode-select` installer.
- Homebrew is installed with its official installer when `brew` is absent.
- All dotfiles applications and tools are then installed with Homebrew; no other third-party package manager is used.

```sh
./install/macos.sh
./install/macos.sh --dry-run
```

On a factory-fresh system, the first run requests Xcode Command Line Tools and then exits. Complete the macOS installer dialog and rerun the script; it will bootstrap Homebrew, install all active dependencies, link WezTerm, Fish, Zellij, and Helix under `${XDG_CONFIG_HOME:-$HOME/.config}`, register Homebrew Fish in `/etc/shells`, and run `chsh`.

## Windows preset

Baseline:

- Windows with WinGet
- A fresh, initialized Arch Linux distribution named `Arch` running on WSL2
- This repository accessible from Arch WSL

Package managers:

- WinGet on the Windows host
- Pacman inside the Arch Linux guest

```powershell
.\install\windows.ps1
.\install\windows.ps1 -DryRun
```

The Windows host contains only WezTerm and `.wezterm.lua`. WinGet installs WezTerm. The script verifies that `Arch` exists, runs under WSL2, and contains `/etc/arch-release`; it then invokes the Arch/Pacman preset inside WSL.

Fish, Zellij, Helix, Starship, mise, zoxide, Ruff, and the language toolchains are installed inside Arch WSL. Fish becomes the WSL login shell. No native Windows Helix or Zellij configuration is created.

## Linux preset

Baseline: an already installed Linux distribution. The script does not install Homebrew, Linuxbrew, another package manager, or general build prerequisites.

The script reads `/etc/os-release`, displays the detected distribution, and requires confirmation before package installation. Use `--yes` only for a previously confirmed unattended run.

```sh
./install/linux.sh
./install/linux.sh --dry-run
./install/linux.sh --yes
```

Supported distribution families and managers:

- Arch/Manjaro — Pacman
- Debian/Ubuntu — APT
- Fedora/RHEL/CentOS — DNF
- openSUSE/SLES — Zypper

All dependencies are requested directly through the detected distribution manager; no secondary language-package manager is used.

## Dry-run behavior

Dry-run prints system bootstrapping, package installation, backups, links, `/etc/shells`, environment, and `chsh` operations without applying them. Distribution detection and prerequisite checks still run.
