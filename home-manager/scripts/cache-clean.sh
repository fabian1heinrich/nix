#!/usr/bin/env bash

set -euo pipefail

program_name="${0##*/}"
dry_run=0
failed=0
planned_kib=0
deleted_kib=0
targets=()
known_targets=(vscode codex lima colima zarf)

usage() {
  cat <<EOF
Usage: ${program_name} [--dry-run] [TARGET...]

Remove regenerable macOS application caches. Without TARGET, all targets are
cleaned. Linux support is intentionally a placeholder for now.

Targets: vscode codex lima colima zarf all

Options:
  --dry-run   Report what would be deleted without changing anything
  -h, --help  Show this help
EOF
}

die() {
  printf '%s: %s\n' "$program_name" "$*" >&2
  exit 2
}

while (($# > 0)); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      targets+=("$@")
      break
      ;;
    -*) die "unknown option: $1" ;;
    *) targets+=("$1") ;;
  esac
  shift
done

((${#targets[@]} > 0)) || targets=(all)
for target in "${targets[@]}"; do
  case "$target" in
    vscode | codex | lima | colima | zarf | all) ;;
    *) die "unknown target: $target" ;;
  esac
done

case "$(uname -s)" in
  Darwin) ;;
  Linux)
    printf '%s: Linux cache cleanup is not implemented yet; no files changed.\n' "$program_name" >&2
    exit 1
    ;;
  *) die "unsupported operating system" ;;
esac

[[ -n "${HOME:-}" && "$HOME" != / ]] || die "HOME must name a non-root directory"

vscode_root="$HOME/Library/Application Support/Code"
codex_root="$HOME/.codex"
cache_root="$HOME/Library/Caches"
zarf_cache="$HOME/.zarf-cache"

selected() {
  local requested

  for requested in "${targets[@]}"; do
    [[ "$requested" == all || "$requested" == "$1" ]] && return 0
  done
  return 1
}

size_kib() {
  [[ -e "$1" || -L "$1" ]] || {
    printf '0\n'
    return
  }
  du -sk -- "$1" 2>/dev/null | awk 'NR == 1 { print $1 }'
}

human_size() {
  awk -v kib="$1" 'BEGIN {
    value = kib * 1024
    split("B KiB MiB GiB TiB", units, " ")
    unit = 1
    while (value >= 1024 && unit < 5) {
      value /= 1024
      unit++
    }
    format = unit == 1 ? "%.0f %s\n" : "%.1f %s\n"
    printf format, value, units[unit]
  }'
}

safe_path() {
  case "$1" in
    "$vscode_root"/* | "$codex_root"/* | "$cache_root/lima"/* | "$cache_root/colima"/* | "$zarf_cache") ;;
    *) die "refusing unsafe removal path: $1" ;;
  esac
}

clean_path() {
  local target="$1"
  local label="$2"
  local path="$3"
  local kib

  kib="$(size_kib "$path")"
  ((kib > 0)) || return 0

  planned_kib=$((planned_kib + kib))
  printf '%-8s %9s  %s\n' "$target" "$(human_size "$kib")" "$label"

  if ((dry_run == 0)); then
    safe_path "$path"
    rm -rf -- "$path"
    deleted_kib=$((deleted_kib + kib))
  fi
}

require_stopped() {
  local target="$1"
  local process_name="$2"
  local pattern="$3"

  ((dry_run == 0)) || return 0
  if ! command -v pgrep >/dev/null 2>&1; then
    printf '%s: refusing to clean %s because pgrep is unavailable\n' "$program_name" "$target" >&2
  elif ! pgrep -f "$pattern" >/dev/null 2>&1; then
    return 0
  else
    printf '%s: refusing to clean %s while %s is running\n' "$program_name" "$target" "$process_name" >&2
  fi

  failed=1
  return 1
}

clean_vscode() {
  require_stopped vscode "VS Code" '/Visual Studio Code\.app/|/Code Helper' || return 0

  clean_path vscode "application cache" "$vscode_root/Cache"
  clean_path vscode "compiled code cache" "$vscode_root/CachedData"
  clean_path vscode "GPU cache" "$vscode_root/GPUCache"
  clean_path vscode "service-worker cache" "$vscode_root/Service Worker"
  clean_path vscode "downloaded extension packages" "$vscode_root/CachedExtensionVSIXs"
  clean_path vscode "agent SDK cache" "$vscode_root/agent-host/sdk-cache"
  clean_path vscode "logs" "$vscode_root/logs"
  clean_path vscode "crash reports" "$vscode_root/Crashpad"
}

clean_codex() {
  local backup_path

  require_stopped codex "Codex" '/[Cc]odex[^/[:space:]]*([[:space:]]|$)' || return 0

  clean_path codex "cache" "$codex_root/cache"
  clean_path codex "stale marketplace upgrades" "$codex_root/.tmp/marketplaces/.staging"
  if [[ -d "$codex_root/.tmp" ]]; then
    while IFS= read -r -d '' backup_path; do
      clean_path codex "temporary plugin backup" "$backup_path"
    done < <(find "$codex_root/.tmp" -maxdepth 1 -type d -name 'plugins-backup-*' -print0)
  fi
}

clean_lima() {
  if ((dry_run == 0)) && command -v limactl >/dev/null 2>&1; then
    printf '%-8s %9s  %s\n' lima command "prune unreferenced objects"
    limactl prune --keep-referred --yes || failed=1
  fi
  clean_path lima "host download cache" "$cache_root/lima/download"
}

clean_colima() {
  clean_path colima "host download cache" "$cache_root/colima/caches"
}

clean_zarf() {
  clean_path zarf "image and Helm cache" "$zarf_cache"
}

if ((dry_run == 1)); then
  printf 'Dry run; selected cache data:\n'
else
  printf 'Deleting selected caches:\n'
fi

for target in "${known_targets[@]}"; do
  selected "$target" || continue
  case "$target" in
    vscode) clean_vscode ;;
    codex) clean_codex ;;
    lima) clean_lima ;;
    colima) clean_colima ;;
    zarf) clean_zarf ;;
  esac
done

printf '\nTotal selected: %s\n' "$(human_size "$planned_kib")"
if ((dry_run == 1)); then
  ((planned_kib == 0)) || printf 'Run without --dry-run to delete the reported data.\n'
else
  printf 'Deleted:        %s\n' "$(human_size "$deleted_kib")"
fi

exit "$failed"
