#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'error: macos.sh must be run on macOS\n' >&2
  exit 1
fi

dry_run=0

usage() {
  cat <<'EOF'
Usage: ./install/macos.sh [--dry-run]

Bootstraps a factory-fresh macOS installation with Xcode Command Line Tools
and Homebrew, installs all active dotfiles dependencies, hard-links the four
configurations, then changes the shell to Fish.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

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

ensure_command_line_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi

  if (( dry_run )); then
    run xcode-select --install
    printf 'DRY RUN: rerun this installer after Command Line Tools installation completes\n'
    return
  fi

  if ! xcode-select --install; then
    printf '%s\n' 'Command Line Tools installation may already be in progress.'
  fi
  printf '%s\n' \
    'Xcode Command Line Tools installation was requested.' \
    'Complete the system installer, then run this script again.'
  exit 0
}

install_homebrew() {
  if (( dry_run )); then
    printf '%s\n' 'DRY RUN: install Homebrew with the official installer from brew.sh'
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

find_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
  fi
}

set_default_shell() {
  local fish_path="$1"

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

ensure_command_line_tools

brew_cmd="$(find_homebrew)"
if [[ -z "$brew_cmd" ]]; then
  install_homebrew
  brew_cmd="$(find_homebrew)"
fi

if [[ -z "$brew_cmd" && "$dry_run" -eq 1 ]]; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    brew_cmd=/opt/homebrew/bin/brew
  else
    brew_cmd=/usr/local/bin/brew
  fi
fi

if [[ -z "$brew_cmd" ]]; then
  printf 'error: Homebrew installation completed without a discoverable brew executable\n' >&2
  exit 1
fi

if (( dry_run )); then
  if [[ "$brew_cmd" == /opt/homebrew/bin/brew ]]; then
    brew_prefix=/opt/homebrew
  else
    brew_prefix=/usr/local
  fi
else
  brew_prefix="$($brew_cmd --prefix)"
fi

formulae=(
  fish zellij helix starship mise zoxide
  ruff rustup llvm less
)
run "$brew_cmd" install "${formulae[@]}"
run "$brew_cmd" install --cask wezterm
run "$brew_prefix/opt/rustup/bin/rustup" toolchain install stable --profile minimal --component rustfmt,rust-analyzer

apply_args=()
if (( dry_run )); then
  apply_args+=(--dry-run)
fi
XDG_CONFIG_HOME="$config_home" DOTFILES_BACKUP_DIR="$backup_root" \
  "$repo_root/apply/apply.sh" "${apply_args[@]}"

set_default_shell "$brew_prefix/bin/fish"

printf 'macOS installation complete. Log out and back in to use Fish as the login shell.\n'
