# Dotfiles Installers

Each platform has one explicit preset and uses only its applicable system package manager. The installers deploy the configurations and change the login shell to Fish.

Active dependencies include WezTerm, Fish, Zellij, Helix, Starship, mise, zoxide, Ruff, and the Rust/C/C++ language tools used by Helix. Ruby, OpenJDK, .NET, and Flutter remain optional and are not installed.

Existing configuration targets are moved into a timestamped directory under `~/.dotfiles-backups/` before hard links are created. The repository and configuration directory must be on the same filesystem. Changing the login shell may ask for a password.

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

On a factory-fresh system, the first run requests Xcode Command Line Tools and then exits. Complete the macOS installer dialog and rerun the script; it will bootstrap Homebrew, install all active dependencies, hard-link WezTerm, Fish, Zellij, and Helix files under `${XDG_CONFIG_HOME:-$HOME/.config}`, register Homebrew Fish in `/etc/shells`, and run `chsh`.

## Windows preset

Baseline:

- Windows with WinGet
- A fresh, initialized Arch Linux distribution named `archlinux` running on WSL2
- This repository accessible from Arch WSL

Package managers:

- WinGet on the Windows host
- Pacman inside the Arch Linux guest
- rustup for the Rust toolchain and its editor components

```powershell
.\install\windows.ps1
.\install\windows.ps1 -DryRun
```

The Windows host contains Windows Terminal and its `settings.json`. WinGet installs Windows Terminal, and `apply/windows.ps1` synchronizes its configuration with `archlinux` WSL as the default profile. The installer verifies that `archlinux` exists, runs under WSL2, and contains `/etc/arch-release`; it then invokes the Arch/Pacman preset inside WSL.

Fish, Zellij, Helix, Starship, mise, zoxide, Ruff, and the language toolchains are installed inside Arch WSL. Fish becomes the WSL login shell. No native Windows Helix or Zellij configuration is created.

## Arch Linux preset

Baseline: an already installed Arch Linux, Manjaro, or compatible Arch-based distribution with Pacman. The script does not bootstrap Pacman or install general system prerequisites.

The script reads `/etc/os-release`, rejects non-Arch-based distributions, and requires confirmation before package installation. Use `--yes` only for a previously confirmed unattended run.

```sh
./install/linux.sh
./install/linux.sh --dry-run
./install/linux.sh --yes
```

Pacman manages the system applications and native tools: WezTerm, Fish, Zellij, Helix, Starship, mise, zoxide, Ruff, rustup, Clang, and less. Rustup manages the stable Rust toolchain plus the `rustfmt` and `rust-analyzer` components. Cargo is not used to install applications that are available as Arch packages.

## Dry-run behavior

Dry-run prints system bootstrapping, package installation, backups, hard links, `/etc/shells`, environment, and `chsh` operations without applying them. Distribution detection and prerequisite checks still run.
