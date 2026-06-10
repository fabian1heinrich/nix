#!/usr/bin/env bash

set -euo pipefail

symbol="📦"

clean_docker() {
  env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION docker "$@"
}

current_context() {
  clean_docker context show 2>/dev/null
}

context_host() {
  local context="$1"

  clean_docker context inspect "$context" 2>/dev/null |
    jq -r '.[0].Endpoints.docker.Host // empty'
}

socket_from_host() {
  local host="$1"

  case "$host" in
    unix://*) printf '%s\n' "${host#unix://}" ;;
    *) printf '\n' ;;
  esac
}

context_is_visible() {
  local context="$1"

  [[ -n "$context" && "$context" != "default" ]]
}

context_is_down() {
  local context="$1"
  local host socket

  host="$(context_host "$context")"
  socket="$(socket_from_host "$host")"

  [[ -n "$socket" && ! -S "$socket" ]]
}

print_context() {
  local context="$1"

  if context_is_down "$context"; then
    printf '%s%s:down\n' "$symbol" "$context"
  else
    printf '%s%s\n' "$symbol" "$context"
  fi
}

main() {
  local context

  context="$(current_context)"
  context_is_visible "$context" || exit 1

  print_context "$context"
}

main "$@"
