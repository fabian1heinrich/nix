#!/usr/bin/env bash

set -euo pipefail

docker_cmd=(env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION docker)
context="$("${docker_cmd[@]}" context show 2>/dev/null)"

[[ -n "$context" && "$context" != "default" ]] || exit 1

case "$(uname -s)" in
  Linux)
    [[ "$context" == "podman-rootless" ]] && exit 1
    printf '📦%s\n' "$context"
    exit
    ;;
  Darwin)
    if [[ "$context" != "podman" ]]; then
      printf '📦%s\n' "$context"
      exit
    fi
    rootful="$(podman machine inspect --format '{{.Rootful}}' \
      "${PODMAN_MACHINE:-podman-machine-default}" 2>/dev/null)" || exit 1
    ;;
  *)
    printf '📦%s\n' "$context"
    exit
    ;;
esac

mode=rootless
[[ "$rootful" == true ]] && mode=rootful
printf '📦%s:%s\n' "$context" "$mode"
