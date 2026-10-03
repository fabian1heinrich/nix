set shell := ["bash", "-uc"]

podman := "env -u CONTAINER_CONNECTION -u CONTAINER_HOST podman"
docker := "env -u DOCKER_CONTEXT -u DOCKER_HOST docker"
machine_format := "{{.Rootful}} {{.ConnectionInfo.PodmanSocket.Path}}"
running_format := "{{if .Running}}{{.Name}}{{end}}"
state_format := "{{.State}}"
machine_name_format := "{{.Name}}"

_podman-machine-host:
    @if [[ "$(uname -s)" != Darwin ]]; then \
        echo "Podman machine recipes are only available on macOS; Linux uses the native rootless Podman socket." >&2; \
        exit 1; \
    fi

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-eval:
    nix flake check --all-systems --no-build

nix-check:
    nix flake check

nix-shellcheck:
    nix build --no-link .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck

nix-fmt:
    nix fmt

nix-update:
    nix flake update

# Create a macOS Podman VM and Docker context
podman-create mode="rootless": _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    mode={{ quote(mode) }}
    machine=podman
    rootful=false
    args=()
    if [[ "$mode" == rootful ]]; then machine=podman-rootful; rootful=true; args=(--rootful); fi
    {{ podman }} machine inspect "$machine" >/dev/null 2>&1 || {{ podman }} machine init "${args[@]}" "$machine"
    read -r actual socket < <({{ podman }} machine inspect --format '{{ machine_format }}' "$machine")
    [[ "$actual" == "$rootful" ]] || { echo "$machine has Rootful=$actual" >&2; exit 1; }
    if {{ docker }} context inspect "$machine" >/dev/null 2>&1; then action=update; else action=create; fi
    {{ docker }} context "$action" "$machine" --docker "host=unix://$socket" >/dev/null

# Create if necessary and start a macOS Podman VM
podman-start mode="rootless": (podman-create mode)
    #!/usr/bin/env bash
    set -eu
    mode={{ quote(mode) }}
    machine=podman
    [[ "$mode" == rootful ]] && machine=podman-rootful
    running="$({{ podman }} machine list --format '{{ running_format }}' | sed '/^$/d')"
    if [[ -n "$running" && "$running" != "$machine" ]]; then
      {{ podman }} machine stop "$running"
    fi
    [[ "$running" == "$machine" ]] || {{ podman }} machine start "$machine"

# Stop a macOS Podman VM
podman-stop mode="rootless": _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    mode={{ quote(mode) }}
    machine=podman
    [[ "$mode" == rootful ]] && machine=podman-rootful
    if state="$({{ podman }} machine inspect --format '{{ state_format }}' "$machine" 2>/dev/null)" && [[ "$state" != stopped ]]; then
      {{ podman }} machine stop "$machine"
    fi

# Delete all macOS Podman VMs and their matching Docker contexts
podman-delete: _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    machines="$({{ podman }} machine list --format '{{ machine_name_format }}')"
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
