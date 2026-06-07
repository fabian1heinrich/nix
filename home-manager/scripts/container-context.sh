#!/usr/bin/env bash

set -euo pipefail

os="$(uname -s)"

die() {
  printf 'container-context: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  container-context colima [profile]
  container-context podman <rootless|rootful> <context> [machine]
EOF
}

clean_docker() {
  env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION -u DOCKER_CONTEXT docker "$@"
}

valid_mode() {
  case "${1:-}" in
    rootless | rootful) ;;
    *) die "expected mode rootless or rootful, got: ${1:-<empty>}" ;;
  esac
}

require_darwin_machine() {
  if [[ "$os" == "Darwin" && -z "${1:-}" ]]; then
    die "Podman machine name is required on macOS"
  fi
}

wait_docker_api() {
  local socket="$1"

  for _ in {1..80}; do
    if env -u DOCKER_CONTEXT -u CONTAINER_HOST -u CONTAINER_CONNECTION DOCKER_HOST="unix://$socket" docker version >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  die "Docker API did not become ready: $socket"
}

use_docker_socket() {
  local context="$1"
  local label="$2"
  local socket="$3"

  [[ -S "$socket" ]] || die "$label socket not found: $socket"
  wait_docker_api "$socket"

  if clean_docker context inspect "$context" >/dev/null 2>&1; then
    clean_docker context update "$context" --description "$label" --docker "host=unix://$socket" >/dev/null
  else
    clean_docker context create "$context" --description "$label" --docker "host=unix://$socket" >/dev/null
  fi

  clean_docker context use "$context"
}

machine_state() {
  podman machine inspect "$1" 2>/dev/null | jq -r '.[0].State // empty'
}

fix_applehv_ignition() {
  local machine="$1"
  local ign="$HOME/.config/containers/podman/machine/applehv/${machine}.ign"
  local tmp

  [[ -f "$ign" ]] || return 0

  tmp="$(mktemp)"
  jq 'walk(if type == "object" then del(.verification) else . end) | if (.ignition.config.replace.source? // null) == null then del(.ignition.config.replace) else . end' "$ign" >"$tmp"
  mv "$tmp" "$ign"
}

other_darwin_machines() {
  local machine="$1"

  podman machine list --format json |
    jq -r --arg machine "$machine" '.[] | select(.Name != $machine and (.Running or .Starting)) | .Name'
}

first_other_darwin_machine() {
  local machine="$1"

  podman machine list --format json |
    jq -r --arg machine "$machine" 'first(.[] | select(.Name != $machine and (.Running or .Starting)) | .Name) // empty'
}

stop_other_darwin_machines() {
  local machine="$1"
  local other

  while IFS= read -r other; do
    [[ -n "$other" ]] || continue
    podman machine stop "$other" >/dev/null
  done < <(other_darwin_machines "$machine")

  for _ in {1..60}; do
    other="$(first_other_darwin_machine "$machine")"
    [[ -z "$other" ]] && return 0
    sleep 0.5
  done

  die "another Podman machine is still active: $other"
}

up_darwin_podman() {
  local mode="$1"
  local machine="$2"
  local init_args=()
  local state

  if podman machine inspect "$machine" >/dev/null 2>&1; then
    state="$(machine_state "$machine")"
  else
    [[ "$mode" == "rootful" ]] && init_args+=(--rootful)
    podman machine init "${init_args[@]}" "$machine" >/dev/null
    state=""
  fi

  if [[ "$state" != "running" ]]; then
    stop_other_darwin_machines "$machine"
    fix_applehv_ignition "$machine"
    podman machine start "$machine" >/dev/null
  fi
}

up_linux_rootful_podman() {
  local socket="/run/podman/podman.sock"
  local podman_bin

  if [[ ! -S "$socket" ]]; then
    if systemctl cat podman.socket >/dev/null 2>&1; then
      sudo systemctl start podman.socket
    else
      podman_bin="$(readlink -f "$(command -v podman)")"
      sudo install -d -m 0755 /run/podman
      sudo systemctl stop podman-rootful-api.service >/dev/null 2>&1 || true
      sudo rm -f "$socket"
      sudo systemd-run --unit=podman-rootful-api --collect --property=Restart=on-failure "$podman_bin" system service --time=0 "unix://$socket"
    fi

    for _ in {1..50}; do
      [[ -S "$socket" ]] && break
      sleep 0.1
    done
  fi

  [[ -S "$socket" ]] || die "rootful Podman socket was not created: $socket"
  sudo chgrp "$(id -gn)" "$socket"
  sudo chmod 0660 "$socket"
}

up_podman() {
  local mode="$1"
  local machine="${2:-}"

  valid_mode "$mode"
  require_darwin_machine "$machine"

  case "$os:$mode" in
    Darwin:*) up_darwin_podman "$mode" "$machine" ;;
    Linux:rootless) systemctl --user start podman.socket || true ;;
    Linux:rootful) up_linux_rootful_podman ;;
    *) die "unsupported Podman mode for $os: $mode" ;;
  esac
}

podman_socket() {
  local mode="$1"
  local machine="$2"

  case "$os:$mode" in
    Darwin:*) printf '%s/.tmp/podman/%s-api.sock\n' "$HOME" "$machine" ;;
    Linux:rootless) printf '%s/podman/podman.sock\n' "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" ;;
    Linux:rootful) printf '/run/podman/podman.sock\n' ;;
    *) die "unsupported Podman mode for $os: $mode" ;;
  esac
}

use_colima_context() {
  local profile="${1:-default}"
  local info context label status runtime socket

  info="$(
    colima list --json |
      jq -sc --arg profile "$profile" '[.[] | if type == "array" then .[] else . end | select(.name == $profile)][0] // empty'
  )"
  [[ -n "$info" ]] || die "Colima profile not found: $profile"

  status="$(jq -r '.status // empty' <<<"$info")"
  runtime="$(jq -r '.runtime // empty' <<<"$info")"
  [[ "$runtime" == "docker" ]] || die "Colima profile does not use the Docker runtime: $profile"

  if [[ "$status" != "Running" ]]; then
    colima start "$profile" >/dev/null
  fi

  context="colima"
  label="Colima"
  if [[ "$profile" != "default" ]]; then
    context="colima-$profile"
    label="Colima $profile"
  fi

  socket="$HOME/.colima/$profile/docker.sock"
  use_docker_socket "$context" "$label" "$socket"
}

use_podman_context() {
  local mode="$1"
  local context="$2"
  local machine="${3:-}"
  local socket label connection

  up_podman "$mode" "$machine" >/dev/null

  socket="$(podman_socket "$mode" "$machine")"
  label="Podman $mode"

  if [[ "$os" == "Darwin" ]]; then
    connection="$machine"
    [[ "$mode" == "rootful" ]] && connection="${machine}-root"
    podman system connection default "$connection" >/dev/null
  fi

  use_docker_socket "$context" "$label" "$socket"
}

main() {
  case "${1:-}" in
    colima)
      [[ "$#" -le 2 ]] || {
        usage
        exit 2
      }
      use_colima_context "${2:-}"
      ;;
    podman)
      [[ "$#" -ge 3 && "$#" -le 4 ]] || {
        usage
        exit 2
      }
      use_podman_context "$2" "$3" "${4:-}"
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
