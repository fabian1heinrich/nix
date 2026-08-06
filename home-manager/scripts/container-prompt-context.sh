#!/usr/bin/env bash

set -euo pipefail

docker_cmd=(env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION docker)
context="$("${docker_cmd[@]}" context show 2>/dev/null)"

[[ -n "$context" && "$context" != "default" ]] || exit 1

timeout 1s "${docker_cmd[@]}" --context "$context" version \
  --format '{{.Server.Version}}' >/dev/null 2>&1 || exit 1

if [[ "$context" != "podman" ]]; then
  printf '📦%s\n' "$context"
  exit
fi

case "$(uname -s)" in
  Darwin)
    rootful="$(podman machine inspect --format '{{.Rootful}}' \
      "${PODMAN_MACHINE:-podman-machine-default}" 2>/dev/null)" || exit 1
    ;;
  Linux)
    rootless="$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" || exit 1
    rootful=true
    [[ "$rootless" == true ]] && rootful=false
    ;;
  *) exit 1 ;;
esac

mode=rootless
[[ "$rootful" == true ]] && mode=rootful
printf '📦%s:%s\n' "$context" "$mode"
