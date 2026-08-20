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

Supports Arch Linux and compatible Arch-based distributions, installs active
dotfiles dependencies with Pacman, hard-links configurations, and changes the
login shell to Fish. No package manager is bootstrapped.

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
distro_like="${distro_like,,}"
distro_name="${PRETTY_NAME:-$ID}"

if (( wsl_arch_mode )) && [[ "$distro_id" != "arch" ]]; then
  printf 'error: --wsl-arch requires Arch Linux, detected %s\n' "$distro_name" >&2
  exit 1
fi

case "$distro_id:$distro_like" in
  arch:*|manjaro:*|*:arch*) ;;
  *)
    printf 'error: unsupported Linux distribution: %s; only Arch-based distributions are supported\n' "$distro_name" >&2
    exit 1
    ;;
esac

command -v pacman >/dev/null 2>&1 || { printf 'error: pacman not found\n' >&2; exit 1; }

printf 'Detected Linux distribution: %s (ID=%s)\n' "$distro_name" "$distro_id"
if (( ! assume_yes )); then
  [[ -t 0 ]] || {
    printf 'error: interactive distribution confirmation required; use --yes to confirm\n' >&2
    exit 1
  }
  read -r -p "Install dependencies with Pacman? [y/N] " confirmation
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

set_default_shell() {
  local current_shell fish_path
  fish_path="$(command -v fish 2>/dev/null || printf '/usr/bin/fish')"

  if ! grep -Fqx "$fish_path" /etc/shells; then
    if (( dry_run )); then
      printf 'DRY RUN: add %q to /etc/shells with sudo\n' "$fish_path"
    else
      printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
  fi

  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$(readlink -f "$current_shell")" != "$(readlink -f "$fish_path")" ]]; then
    run sudo chsh -s "$fish_path" "$USER"
  else
    printf 'fish: already the default shell\n'
  fi
}

install_packages() {
  local packages=(
    fish zellij helix starship mise zoxide ruff
    rustup clang less
  )
  if (( ! wsl_arch_mode )); then
    packages+=(wezterm)
  fi
  run sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

migrate_rust_analyzer() {
  if pacman -Qq | grep -Fqx rust-analyzer; then
    run sudo pacman -R --noconfirm rust-analyzer
  fi
}

install_rust_toolchain() {
  run rustup toolchain install stable \
    --profile minimal \
    --component rustfmt,rust-analyzer
}

migrate_rust_analyzer
install_packages
install_rust_toolchain

apply_args=()
if (( dry_run )); then
  apply_args+=(--dry-run)
fi
if (( wsl_arch_mode )); then
  apply_args+=(fish zellij helix)
fi
XDG_CONFIG_HOME="$config_home" DOTFILES_BACKUP_DIR="$backup_root" \
  "$repo_root/apply/apply.sh" "${apply_args[@]}"

set_default_shell

printf 'Linux installation complete. Log out and back in to use Fish as the login shell.\n'
