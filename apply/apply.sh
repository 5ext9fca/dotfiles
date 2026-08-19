#!/usr/bin/env bash
set -euo pipefail

dry_run=0
components=()

usage() {
  cat <<'EOF'
Usage: ./apply/apply.sh [--dry-run] [component ...]

Hard-links the repository's WezTerm, Fish, Zellij, and Helix configuration
files into ${XDG_CONFIG_HOME:-$HOME/.config}. Existing conflicting targets are
moved to a timestamped directory under ~/.dotfiles-backups first.

When components are provided, only wezterm, fish, zellij, and/or helix are
applied. All four are applied by default.

The repository and configuration directory must be on the same filesystem.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) components+=("$1") ;;
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

backup_target() {
  local target="$1" relative_target="$2"
  local backup_target_path="$backup_root/$relative_target"

  run mkdir -p "$(dirname -- "$backup_target_path")"
  run mv "$target" "$backup_target_path"
  printf 'backed up %s to %s\n' "$target" "$backup_target_path"
}

prepare_component_directory() {
  local component="$1" target_dir="$2"

  if [[ -L "$target_dir" || ( -e "$target_dir" && ! -d "$target_dir" ) ]]; then
    backup_target "$target_dir" "$component"
    run mkdir -p "$target_dir"
    return 1
  fi

  run mkdir -p "$target_dir"
  return 0
}

link_file() {
  local component="$1" source="$2" target="$3" relative_path="$4"

  if [[ -e "$target" && "$source" -ef "$target" ]]; then
    printf '%s: already linked\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target" "$component/$relative_path"
  fi

  run mkdir -p "$(dirname -- "$target")"
  run ln "$source" "$target"
  printf '%s: hard-linked to %s\n' "$target" "$source"
}

apply_component() {
  local component="$1"
  local source_dir="$repo_root/$component"
  local target_dir="$config_home/$component"
  local source relative_path target
  local target_dir_kept=0

  [[ -d "$source_dir" ]] || {
    printf 'error: missing configuration directory: %s\n' "$source_dir" >&2
    exit 1
  }

  if prepare_component_directory "$component" "$target_dir"; then
    target_dir_kept=1
  fi

  while IFS= read -r -d '' source; do
    relative_path="${source#"$source_dir/"}"
    target="$target_dir/$relative_path"

    if (( dry_run && ! target_dir_kept )); then
      run mkdir -p "$(dirname -- "$target")"
      run ln "$source" "$target"
      printf '%s: hard-linked to %s\n' "$target" "$source"
    else
      link_file "$component" "$source" "$target" "$relative_path"
    fi
  done < <(find "$source_dir" -type f -print0)

  while IFS= read -r -d '' source; do
    relative_path="${source#"$source_dir/"}"
    run mkdir -p "$target_dir/$relative_path"
  done < <(find "$source_dir" -mindepth 1 -type d -print0)
}

if (( ${#components[@]} == 0 )); then
  components=(wezterm fish zellij helix)
fi

for component in "${components[@]}"; do
  case "$component" in
    wezterm|fish|zellij|helix) ;;
    *) printf 'error: unknown component: %s\n' "$component" >&2; exit 2 ;;
  esac
  apply_component "$component"
done

printf 'Configuration hard links applied successfully.\n'
