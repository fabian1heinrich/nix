set shell := ["bash", "-uc"]

podman_machine := env_var_or_default("PODMAN_MACHINE", "podman")
podman := "env -u CONTAINER_CONNECTION -u CONTAINER_HOST podman"
docker := "env -u DOCKER_CONTEXT -u DOCKER_HOST docker"
machine_format := "{{.Rootful}} {{.ConnectionInfo.PodmanSocket.Path}}"
running_format := "{{if .Running}}{{.Name}}{{end}}"
state_format := "{{.State}}"

_podman-machine-host:
    @if [[ "$(uname -s)" != Darwin ]]; then \
        echo "Podman machine recipes are only available on macOS; Linux uses the native rootless Podman socket." >&2; \
        exit 1; \
    fi

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-check:
    nix flake check --all-systems --no-build

nix-shellcheck:
    nix build --no-link .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck

nix-fmt:
    nix fmt

nix-update:
    nix flake update

# Create a macOS Podman VM and Docker context
podman-create: _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    machine="{{ podman_machine }}"
    case "$machine" in
      podman) rootful=false; args=() ;;
      podman-rootful) rootful=true; args=(--rootful) ;;
      *) echo "unsupported PODMAN_MACHINE: $machine" >&2; exit 2 ;;
    esac
    {{ podman }} machine inspect "$machine" >/dev/null 2>&1 || {{ podman }} machine init "${args[@]}" "$machine"
    read -r actual socket < <({{ podman }} machine inspect --format '{{ machine_format }}' "$machine")
    [[ "$actual" == "$rootful" ]] || { echo "$machine has Rootful=$actual" >&2; exit 1; }
    if {{ docker }} context inspect "$machine" >/dev/null 2>&1; then action=update; else action=create; fi
    {{ docker }} context "$action" "$machine" --docker "host=unix://$socket" >/dev/null

# Create if necessary and start a macOS Podman VM
podman-start: podman-create
    #!/usr/bin/env bash
    set -eu
    running="$({{ podman }} machine list --format '{{ running_format }}' | sed '/^$/d')"
    if [[ -n "$running" && "$running" != "{{ podman_machine }}" ]]; then
      {{ podman }} machine stop "$running"
    fi
    [[ "$running" == "{{ podman_machine }}" ]] || {{ podman }} machine start "{{ podman_machine }}"

# Stop a macOS Podman VM
podman-stop: _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    if state="$({{ podman }} machine inspect --format '{{ state_format }}' '{{ podman_machine }}' 2>/dev/null)" && [[ "$state" != stopped ]]; then
      {{ podman }} machine stop "{{ podman_machine }}"
    fi

# Delete a macOS Podman VM and Docker context
podman-delete: _podman-machine-host
    #!/usr/bin/env bash
    set -eu
    if {{ podman }} machine inspect "{{ podman_machine }}" >/dev/null 2>&1; then
      {{ podman }} machine rm --force "{{ podman_machine }}"
    fi
    if {{ docker }} context inspect "{{ podman_machine }}" >/dev/null 2>&1; then
      {{ docker }} context rm --force "{{ podman_machine }}" >/dev/null
    fi

switch-legendre:
    sudo darwin-rebuild switch --flake .#legendre

switch-ubuntu-dev:
    home-manager switch --flake .#ubuntu-dev

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
    brew cleanup -s
    rm -rf "$(brew --cache)"
