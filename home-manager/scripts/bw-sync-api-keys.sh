set -euo pipefail

emit_shell_exports=0
if [ "${1:-}" = "--export-shell" ]; then
  emit_shell_exports=1
  shift
fi

if [ "$#" -ne 0 ]; then
  printf 'bw-sync-api-keys: unknown arguments: %s\n' "$*" >&2
  exit 2
fi

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

hm_session_vars_candidates=(
  "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
  "/etc/profiles/per-user/${USER}/etc/profile.d/hm-session-vars.sh"
)

log() {
  printf 'bw-sync-api-keys: %s\n' "$*" >&2
}

session_valid() {
  local session="$1"
  [ -n "$session" ] || return 1
  bw list items --search "__bw_probe__" --session "$session" >/dev/null 2>&1
}

if ! bw login --check >/dev/null 2>&1; then
  bw config server "https://vault.bitwarden.eu" >/dev/null

  log "not logged in; run 'bw login' once on this host"
  exit 0
fi

if ! session_valid "${BW_SESSION:-}"; then
  if ! [ -t 0 ]; then
    log "vault is locked and no TTY is available for unlock"
    exit 0
  fi

  export BW_SESSION
  BW_SESSION="$(bw unlock --raw)"
fi

if [ -z "${BW_ITEM_ID_OPENAI_API_KEY:-}" ]; then
  for hm_session_vars in "${hm_session_vars_candidates[@]}"; do
    if [ -f "$hm_session_vars" ]; then
      # shellcheck disable=SC1090
      . "$hm_session_vars"
      if [ -n "${BW_ITEM_ID_OPENAI_API_KEY:-}" ]; then
        break
      fi
    fi
  done
fi

missing_item_id_vars=()
for item_id_var in "${item_id_vars[@]}"; do
  item_id="${!item_id_var:-}"
  if [ -z "$item_id" ] || [[ "$item_id" == REPLACE_* ]]; then
    missing_item_id_vars+=("$item_id_var")
  fi
done

if [ "${#missing_item_id_vars[@]}" -gt 0 ]; then
  log "missing item ID env vars: ${missing_item_id_vars[*]}"
  log "set them in home-manager/programs/bitwarden-secrets.nix"
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
  item_id_var="${item_id_vars[$i]}"
  item_id="${!item_id_var}"

  item_json="$(bw get item "$item_id" --session "$BW_SESSION" 2>/dev/null || true)"
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
  log "no matching Bitwarden items found for configured item IDs"
  exit 1
fi

if [ "${#missing[@]}" -gt 0 ]; then
  log "missing keys: ${missing[*]}"
fi
