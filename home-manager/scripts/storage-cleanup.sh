#!/usr/bin/env bash

set -uo pipefail

dry_run=0
threshold_gib=40
failures=0

usage() {
  cat <<'EOF'
Usage: storage-cleanup [--dry-run] [--threshold-gib N]

Run conservative user-level storage cleanup. Zarf's cache is cleared only
when available disk space is below the configured threshold (default: 40 GiB).

Options:
  --dry-run          Show what would be cleaned without changing anything.
  --threshold-gib N  Set the free-space threshold for clearing Zarf's cache.
  -h, --help         Show this help.
EOF
}

log() {
  printf '%s storage-cleanup: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

format_kib() {
  awk -v kib="$1" '
    BEGIN {
      split("KiB MiB GiB TiB", units, " ")
      value = kib
      unit = 1
      while (value >= 1024 && unit < 4) {
        value /= 1024
        unit++
      }
      printf "%.1f %s", value, units[unit]
    }
  '
}

available_kib() {
  df -Pk "$HOME" | awk 'NR == 2 { print $4 }'
}

directory_kib() {
  local path="$1"

  if [ -e "$path" ]; then
    du -sk "$path" 2>/dev/null | awk '{ print $1 }'
  else
    printf '0\n'
  fi
}

run_cleanup() {
  local description="$1"
  shift

  log "$description"
  if ! "$@"; then
    log "failed: $description"
    failures=$((failures + 1))
  fi
}

remove_tree() {
  local path="$1"

  find "$path" -depth -delete
}

cleanup_zarf_temp() {
  local temp_root="$HOME/.tmp"
  local candidate
  local size_kib

  [ -d "$temp_root" ] || return 0

  while IFS= read -r -d '' candidate; do
    size_kib="$(directory_kib "$candidate")"
    if [ "$dry_run" -eq 1 ]; then
      log "would remove stale Zarf temporary directory ($(
        format_kib "$size_kib"
      )): $candidate"
    else
      log "removing stale Zarf temporary directory ($(
        format_kib "$size_kib"
      )): $candidate"
      if ! remove_tree "$candidate"; then
        log "failed to remove: $candidate"
        failures=$((failures + 1))
      fi
    fi
  done < <(
    find "$temp_root" \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      -name 'zarf-*' \
      -mtime +7 \
      -print0
  )
}

cleanup_zarf_cache_if_needed() {
  local free_kib="$1"
  local threshold_kib=$((threshold_gib * 1024 * 1024))
  local cache_path="$HOME/.zarf-cache"
  local cache_kib

  if [ "$free_kib" -ge "$threshold_kib" ]; then
    log "available space is above ${threshold_gib} GiB; keeping Zarf cache"
    return 0
  fi

  if [ ! -d "$cache_path" ]; then
    log "available space is below ${threshold_gib} GiB; no Zarf cache exists"
    return 0
  fi

  cache_kib="$(directory_kib "$cache_path")"
  if /usr/bin/pgrep -x zarf >/dev/null 2>&1; then
    log "available space is below ${threshold_gib} GiB, but Zarf is running; keeping cache"
    return 0
  fi

  if [ "$dry_run" -eq 1 ]; then
    log "would clear Zarf cache ($(format_kib "$cache_kib")): $cache_path"
  else
    log "clearing Zarf cache ($(format_kib "$cache_kib")): $cache_path"
    if ! find "$cache_path" -mindepth 1 -depth -delete; then
      log "failed to clear Zarf cache completely"
      failures=$((failures + 1))
    fi
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --threshold-gib)
      if [ "$#" -lt 2 ]; then
        printf 'storage-cleanup: --threshold-gib requires a value\n' >&2
        exit 2
      fi
      threshold_gib="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'storage-cleanup: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$threshold_gib" in
  '' | *[!0-9]*)
    printf 'storage-cleanup: threshold must be a non-negative integer\n' >&2
    exit 2
    ;;
esac

before_kib="$(available_kib)"
log "starting with $(format_kib "$before_kib") available"

if command -v brew >/dev/null 2>&1; then
  brew_command="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
  brew_command=/opt/homebrew/bin/brew
else
  brew_command=
fi

if [ -n "$brew_command" ]; then
  if [ "$dry_run" -eq 1 ]; then
    run_cleanup \
      "previewing Homebrew cleanup" \
      env HOMEBREW_NO_AUTO_UPDATE=1 "$brew_command" cleanup --dry-run --prune=30
  else
    run_cleanup \
      "cleaning Homebrew downloads older than 30 days" \
      env HOMEBREW_NO_AUTO_UPDATE=1 "$brew_command" cleanup --prune=30
  fi
else
  log "Homebrew is unavailable; skipping"
fi

if command -v nix-collect-garbage >/dev/null 2>&1; then
  if [ "$dry_run" -eq 1 ]; then
    # Nix's --dry-run still removes stale roots, so do not invoke it here.
    log "would collect unreferenced Nix store paths"
  else
    run_cleanup "collecting unreferenced Nix store paths" nix-collect-garbage
  fi
else
  log "nix-collect-garbage is unavailable; skipping"
fi

cleanup_zarf_temp
cleanup_zarf_cache_if_needed "$(available_kib)"

after_kib="$(available_kib)"
if [ "$dry_run" -eq 1 ]; then
  log "dry run complete; no files were changed"
else
  reclaimed_kib=$((after_kib - before_kib))
  if [ "$reclaimed_kib" -lt 0 ]; then
    reclaimed_kib=0
  fi
  log "complete: reclaimed $(format_kib "$reclaimed_kib"); $(format_kib "$after_kib") available"
fi

if [ "$failures" -gt 0 ]; then
  log "completed with $failures failed cleanup step(s)"
  exit 1
fi
