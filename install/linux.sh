#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  printf 'error: linux.sh must be run on Linux or inside WSL\n' >&2
  exit 1
fi

dry_run=0
assume_yes=0
wsl_arch_mode=0

usage() {
  cat <<'EOF'
Usage: ./install/linux.sh [--dry-run] [--yes]

Detects and confirms the current Linux distribution, installs active dotfiles
dependencies with that distribution's package manager, links configurations,
and changes the login shell to Fish. No package manager is bootstrapped.

Internal Windows preset: --wsl-arch requires Arch Linux and skips WezTerm.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --yes) assume_yes=1 ;;
    --wsl-arch) wsl_arch_mode=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ -r /etc/os-release ]] || {
  printf 'error: /etc/os-release is required for distribution detection\n' >&2
  exit 1
}
# shellcheck disable=SC1091
source /etc/os-release
distro_id="${ID,,}"
distro_like="${ID_LIKE:-}"
distro_name="${PRETTY_NAME:-$ID}"

if (( wsl_arch_mode )) && [[ "$distro_id" != "arch" ]]; then
  printf 'error: --wsl-arch requires Arch Linux, detected %s\n' "$distro_name" >&2
  exit 1
fi

printf 'Detected Linux distribution: %s (ID=%s)\n' "$distro_name" "$distro_id"
if (( ! assume_yes )); then
  [[ -t 0 ]] || {
    printf 'error: interactive distribution confirmation required; use --yes to confirm\n' >&2
    exit 1
  }
  read -r -p "Use this distribution's package manager? [y/N] " confirmation
  [[ "$confirmation" == "y" || "$confirmation" == "Y" ]] || {
    printf 'Installation cancelled.\n'
    exit 1
  }
fi

script_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backups/$timestamp}"

run() {
  if (( dry_run )); then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

link_config() {
  local component="$1" source="$2" target="$3"
  local backup_target

  [[ -e "$source" ]] || { printf 'error: missing source: %s\n' "$source" >&2; exit 1; }

  if [[ "$source" == "$target" ]]; then
    printf '%s: source is already the target\n' "$component"
    return
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf '%s: already linked\n' "$component"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target="$backup_root/${target#/}"
    run mkdir -p "$(dirname -- "$backup_target")"
    run mv "$target" "$backup_target"
    printf '%s: backed up existing target to %s\n' "$component" "$backup_target"
  fi

  run mkdir -p "$(dirname -- "$target")"
  run ln -s "$source" "$target"
  printf '%s: linked %s -> %s\n' "$component" "$target" "$source"
}

set_default_shell() {
  local fish_path
  fish_path="$(command -v fish 2>/dev/null || printf '/usr/bin/fish')"

  if ! grep -Fqx "$fish_path" /etc/shells; then
    if (( dry_run )); then
      printf 'DRY RUN: add %q to /etc/shells with sudo\n' "$fish_path"
    else
      printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
  fi

  if [[ "${SHELL:-}" != "$fish_path" ]]; then
    run chsh -s "$fish_path"
  else
    printf 'fish: already the default shell\n'
  fi
}

install_arch_packages() {
  local packages=(
    fish zellij helix starship mise zoxide ruff
    rust rust-analyzer clang less
  )
  if (( ! wsl_arch_mode )); then
    packages+=(wezterm)
  fi
  run sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

install_apt_packages() {
  local packages=(
    fish zellij helix starship mise zoxide ruff
    rustc rustfmt rust-analyzer clang clang-format less
  )
  (( wsl_arch_mode )) || packages+=(wezterm)
  run sudo apt-get update
  run sudo apt-get install -y "${packages[@]}"
}

install_dnf_packages() {
  local packages=(
    fish zellij helix starship mise zoxide ruff
    rust cargo rustfmt rust-analyzer clang clang-tools-extra less
  )
  (( wsl_arch_mode )) || packages+=(wezterm)
  run sudo dnf install -y "${packages[@]}"
}

install_zypper_packages() {
  local packages=(
    fish zellij helix starship mise zoxide ruff
    rust cargo rustfmt rust-analyzer clang clang-tools less
  )
  (( wsl_arch_mode )) || packages+=(wezterm)
  run sudo zypper --non-interactive install "${packages[@]}"
}

case "$distro_id:$distro_like" in
  arch:*|manjaro:*)
    command -v pacman >/dev/null 2>&1 || { printf 'error: pacman not found\n' >&2; exit 1; }
    install_arch_packages
    ;;
  debian:*|ubuntu:*|*:debian*)
    command -v apt-get >/dev/null 2>&1 || { printf 'error: apt-get not found\n' >&2; exit 1; }
    install_apt_packages
    ;;
  fedora:*|rhel:*|centos:*|*:fedora*)
    command -v dnf >/dev/null 2>&1 || { printf 'error: dnf not found\n' >&2; exit 1; }
    install_dnf_packages
    ;;
  opensuse*:*|sles:*|*:suse*)
    command -v zypper >/dev/null 2>&1 || { printf 'error: zypper not found\n' >&2; exit 1; }
    install_zypper_packages
    ;;
  *)
    printf 'error: unsupported Linux distribution: %s\n' "$distro_name" >&2
    exit 1
    ;;
esac

if (( ! wsl_arch_mode )); then
  link_config wezterm "$repo_root/wezterm" "$config_home/wezterm"
fi
link_config fish "$repo_root/fish" "$config_home/fish"
link_config zellij "$repo_root/zellij" "$config_home/zellij"
link_config helix "$repo_root/helix" "$config_home/helix"

set_default_shell

printf 'Linux installation complete. Log out and back in to use Fish as the login shell.\n'
