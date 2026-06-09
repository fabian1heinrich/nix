#!/usr/bin/env bash

set -euo pipefail

emit_shell_exports=0
allow_unlock=1
quiet=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --export-shell)
      emit_shell_exports=1
      ;;
    --no-unlock)
      allow_unlock=0
      ;;
    --quiet)
      quiet=1
      ;;
    *)
      printf 'bw-sync-api-keys: unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
  shift
done

key_names=(
  OPENAI_API_KEY
  ANTHROPIC_API_KEY
  GITHUB_PERSONAL_ACCESS_TOKEN
  BRAVE_API_KEY
  CONTEXT7_API_KEY
)

item_id_vars=(
  BW_ITEM_ID_OPENAI_API_KEY
  BW_ITEM_ID_ANTHROPIC_API_KEY
  BW_ITEM_ID_GITHUB_PERSONAL_ACCESS_TOKEN
  BW_ITEM_ID_BRAVE_API_KEY
  BW_ITEM_ID_CONTEXT7_API_KEY
)

item_ref_vars=(
  BW_ITEM_REF_OPENAI_API_KEY
  BW_ITEM_REF_ANTHROPIC_API_KEY
  BW_ITEM_REF_GITHUB_PERSONAL_ACCESS_TOKEN
  BW_ITEM_REF_BRAVE_API_KEY
  BW_ITEM_REF_CONTEXT7_API_KEY
)

runtime_config_candidates=(
  "${XDG_CONFIG_HOME:-${HOME}/.config}/bw-api-key-items.env"
)

log() {
  printf 'bw-sync-api-keys: %s\n' "$*" >&2
}

info() {
  [ "$quiet" -ne 1 ] || return 0
  log "$@"
}

session_valid() {
  local session="$1"
  [ -n "$session" ] || return 1
  bw list items --search "__bw_probe__" --session "$session" >/dev/null 2>&1
}

load_runtime_config() {
  local config_file

  for config_file in "${runtime_config_candidates[@]}"; do
    if [ -f "$config_file" ]; then
      # shellcheck disable=SC1090
      . "$config_file"
    fi
  done
}

item_ref_for_key() {
  local key_name="$1"
  local item_ref_var="BW_ITEM_REF_${key_name}"
  local item_id_var="BW_ITEM_ID_${key_name}"
  local item_ref="${!item_ref_var:-}"

  if [ -z "$item_ref" ]; then
    item_ref="${!item_id_var:-}"
  fi

  printf '%s' "$item_ref"
}

load_runtime_config

if ! bw login --check >/dev/null 2>&1; then
  bw config server "https://vault.bitwarden.eu" >/dev/null

  info "not logged in; run 'bw login' once on this host"
  exit 0
fi

if ! session_valid "${BW_SESSION:-}"; then
  if [ "$allow_unlock" -ne 1 ]; then
    info "vault is locked; skipping unlock (--no-unlock)"
    exit 0
  fi

  if ! [ -t 0 ]; then
    info "vault is locked and no TTY is available for unlock"
    exit 0
  fi

  info "vault is locked; waiting for unlock (Ctrl+C to cancel)"
  export BW_SESSION
  BW_SESSION="$(bw unlock --raw)"
fi

missing_item_refs=()
for i in "${!key_names[@]}"; do
  key_name="${key_names[$i]}"
  item_ref_var="${item_ref_vars[$i]}"
  item_id_var="${item_id_vars[$i]}"
  item_ref="$(item_ref_for_key "$key_name")"
  if [ -z "$item_ref" ] || [[ "$item_ref" == REPLACE_* ]]; then
    missing_item_refs+=("$item_ref_var or $item_id_var")
  fi
done

if [ "${#missing_item_refs[@]}" -gt 0 ]; then
  log "missing Bitwarden item refs: ${missing_item_refs[*]}"
  log "copy ~/.config/bw-api-key-items.env.example to ~/.config/bw-api-key-items.env and fill it in"
  exit 1
fi

found=0
missing=()

if [ "$emit_shell_exports" -eq 1 ] && [ -n "${BW_SESSION:-}" ]; then
  escaped_session="${BW_SESSION//\'/\'\\\'\'}"
  printf "export BW_SESSION='%s'\n" "$escaped_session"
fi

for i in "${!key_names[@]}"; do
  key_name="${key_names[$i]}"
  item_ref="$(item_ref_for_key "$key_name")"

  item_json="$(bw get item "$item_ref" --session "$BW_SESSION" 2>/dev/null || true)"
  if [ -z "$item_json" ]; then
    missing+=("$key_name")
    continue
  fi

  value="$(
    jq -r --arg key_name "$key_name" '
      .login.password
      // ((.fields // []) | map(select(.name == $key_name) | .value)[0])
      // empty
    ' <<<"$item_json"
  )"

  if [ -n "$value" ]; then
    found=$((found + 1))
    if [ "$emit_shell_exports" -eq 1 ]; then
      escaped_value="${value//\'/\'\\\'\'}"
      printf "export %s='%s'\n" "$key_name" "$escaped_value"
    fi
  else
    missing+=("$key_name")
  fi
done

if [ "$found" -eq 0 ]; then
  log "no matching Bitwarden items found for configured item refs"
  exit 1
fi

if [ "${#missing[@]}" -gt 0 ]; then
  log "missing keys: ${missing[*]}"
fi
