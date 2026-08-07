#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: container-context [--force] <rootless|rootful> [podman-machine]\n' >&2
}

die() {
  printf 'container-context: %s\n' "$*" >&2
  exit 1
}

force=false
args=()
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) args+=("$arg") ;;
  esac
done
set -- "${args[@]}"

mode="${1:-rootless}"
machine="${2:-podman-machine-default}"

[[ $# -le 2 ]] || {
  usage
  exit 2
}
[[ "$mode" == "rootless" || "$mode" == "rootful" ]] || {
  usage
  exit 2
}

case "$(uname -s)" in
  Darwin)
    context=podman
    desired_rootful=false
    [[ "$mode" == "rootful" ]] && desired_rootful=true

    info="$(podman machine inspect --format '{{.State}} {{.Rootful}}' "$machine" 2>/dev/null || true)"
    state="${info%% *}"
    rootful="${info#* }"

    if [[ -z "$state" ]]; then
      init_args=()
      [[ "$mode" == "rootful" ]] && init_args+=(--rootful)
      podman machine init "${init_args[@]}" "$machine" >/dev/null
      state=stopped
      rootful="$desired_rootful"
    fi

    if [[ "$rootful" != "$desired_rootful" ]]; then
      if [[ "$state" == "running" ]]; then
        connection="$machine"
        [[ "$rootful" == true ]] && connection="${machine}-root"
        running="$(podman --connection "$connection" ps --format '{{.Names}}')" ||
          die "unable to check running containers on $machine"
        if [[ -n "$running" && "$force" != true ]]; then
          printf 'container-context: refusing to restart %s with running containers:\n%s\n' \
            "$machine" "$running" >&2
          die 'stop them first or retry with --force'
        fi
        podman machine stop "$machine" >/dev/null
      fi
      podman machine set "--rootful=$desired_rootful" "$machine" >/dev/null
      state=stopped
    fi

    [[ "$state" == "running" ]] || podman machine start "$machine" >/dev/null
    connection="$machine"
    [[ "$mode" == "rootful" ]] && connection="${machine}-root"
    podman system connection default "$connection" >/dev/null
    socket="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' "$machine")"
    ;;
  Linux)
    [[ "$mode" == "rootless" ]] ||
      die 'rootful API contexts are disabled on Linux; use sudo podman or sudo podman compose'
    context=podman-rootless
    systemctl --user start podman.socket
    socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
    ;;
  *) die 'unsupported operating system' ;;
esac

docker=(env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION -u DOCKER_CONTEXT docker)
if "${docker[@]}" context inspect "$context" >/dev/null 2>&1; then
  "${docker[@]}" context update "$context" \
    --description "Podman $mode" --docker "host=unix://$socket" >/dev/null
else
  "${docker[@]}" context create "$context" \
    --description "Podman $mode" --docker "host=unix://$socket" >/dev/null
fi

deadline=$((SECONDS + 20))
until timeout 1s "${docker[@]}" --context "$context" version \
  --format '{{.Server.Version}}' >/dev/null 2>&1; do
  ((SECONDS < deadline)) || die "Docker API did not become ready for context $context"
  sleep 0.25
done

printf '%s\n' "$context"
