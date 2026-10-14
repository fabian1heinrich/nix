set shell := ["bash", "-uc"]

podman := "env -u CONTAINER_CONNECTION -u CONTAINER_HOST podman"
docker := "env -u DOCKER_CONTEXT -u DOCKER_HOST docker"
machine_format := "{{.Rootful}} {{.ConnectionInfo.PodmanSocket.Path}}"
running_format := "{{if .Running}}{{.Name}}{{end}}"
machine_name_format := "{{.Name}}"

# `machine list` appends `*` to the default machine's `Name`, which `machine
# inspect` does not accept back. Machine names cannot contain `*`.
machine_names := "sed -e 's/\\*$//' -e '/^$/d'"

# An unsupported mode fails here rather than falling through to the rootless
# machine.
select_machine := '''
case "$mode" in
  rootless) machine=podman; connection=podman; rootful=false ;;
  rootful) machine=podman-rootful; connection=podman-rootful-root; rootful=true ;;
  *) echo "unsupported podman mode: $mode (expected rootless or rootful)" >&2; exit 1 ;;
esac
'''

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-eval:
    nix flake check --all-systems --no-build

nix-check:
    nix flake check

nix-shellcheck: (_nix-check-one "shellcheck")

nix-actionlint: (_nix-check-one "actionlint")

nix-just: (_nix-check-one "just")

_nix-check-one name:
    nix build --no-link .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).{{ name }}

nix-fmt:
    nix fmt

nix-update:
    nix flake update

_podman-machine-host:
    @if [[ "$(uname -s)" != Darwin ]]; then \
        echo "Podman machine recipes are only available on macOS; Linux uses the native rootless Podman socket." >&2; \
        exit 1; \
    fi

# Create if necessary and start a macOS Podman VM and its Docker context
podman-create mode="rootless": _podman-machine-host
    #!/usr/bin/env bash
    set -euo pipefail
    mode={{ quote(mode) }}
    {{ select_machine }}
    init=(machine init)
    [[ "$rootful" == true ]] && init+=(--rootful)
    init+=("$machine")
    {{ podman }} machine inspect "$machine" >/dev/null 2>&1 || {{ podman }} "${init[@]}"
    # A machine that already existed skipped `machine init` above, so it may
    # not match the requested mode.
    inspected="$({{ podman }} machine inspect --format '{{ machine_format }}' "$machine")"
    read -r actual socket <<<"$inspected"
    [[ "$actual" == "$rootful" ]] || { echo "$machine has Rootful=$actual" >&2; exit 1; }
    if {{ docker }} context inspect "$machine" >/dev/null 2>&1; then action=update; else action=create; fi
    {{ docker }} context "$action" "$machine" --docker "host=unix://$socket" >/dev/null
    # Only one machine may forward the Docker API socket.
    running="$({{ podman }} machine list --format '{{ running_format }}' | {{ machine_names }})"
    if [[ -n "$running" && "$running" != "$machine" ]]; then
      {{ podman }} machine stop "$running"
    fi
    [[ "$running" == "$machine" ]] || {{ podman }} machine start "$machine"

# Delete all macOS Podman VMs and their matching Docker contexts
podman-delete: _podman-machine-host
    #!/usr/bin/env bash
    set -euo pipefail
    machines="$({{ podman }} machine list --format '{{ machine_name_format }}' | {{ machine_names }})"
    if [[ -z "$machines" ]]; then
      echo "No Podman machines exist."
      exit 0
    fi
    while IFS= read -r machine; do
      {{ podman }} machine rm --force "$machine"
      echo "Removed Podman machine $machine"
      if {{ docker }} context inspect "$machine" >/dev/null 2>&1; then
        {{ docker }} context rm --force "$machine" >/dev/null
        echo "Removed Docker context $machine"
      fi
    done <<< "$machines"

switch-legendre:
    sudo nix run .#darwin-rebuild -- switch --flake .#legendre

switch-ubuntu-dev:
    nix run .#home-manager -- switch --flake .#ubuntu-dev

switch-ubuntu-system:
    nix run .#system-manager -- switch --flake .#ubuntu-dev --sudo

switch-ubuntu: switch-ubuntu-system switch-ubuntu-dev

homebrew-upgrade:
    brew update
    brew upgrade
    mas upgrade

homebrew-upgrade-greedy:
    brew update
    brew upgrade --greedy
    mas upgrade

homebrew-cleanup:
    brew cleanup --prune=all -s
