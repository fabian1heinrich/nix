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

# Check Justfile formatting
check-justfile: (_nix-check-one "just")

_nix-check-one name:
    nix build --no-link .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).{{ name }}

nix-fmt:
    nix fmt

nix-update:
    nix flake update

# Filesystem usage and VM/app sizes; avoids walking the Nix store
[macos]
storage-report:
    #!/usr/bin/env bash
    set -euo pipefail
    dir_size() {
      if [[ -d "$2" ]]; then
        du -sk "$2"
      else
        echo 0
      fi | awk -v label="$1" '{ printf "%-20s %6.1f GiB\n", label, $1 / 1048576 }'
    }
    df -k /nix | awk 'NR == 2 { printf "%-20s %6.1f GiB\n", "Nix volume", $3 / 1048576 }'
    dir_size "Linux builder" /private/var/lib/linux-builder
    dir_size "Podman VMs" "$HOME/.local/share/containers/podman/machine"
    dir_size "VS Code" "$HOME/Library/Application Support/Code"
    dir_size "Caches (readable)" "$HOME/Library/Caches" 2>/dev/null || true

# Slow file-by-file measurement of the Nix store
storage-report-nix:
    du -sh /nix/store

# List all Nix GC roots
storage-roots:
    nix-store --gc --print-roots

# Show GC roots retaining a particular store path
storage-why path:
    nix-store --query --roots {{ quote(path) }}

# Run all macOS cleanups, including permanent deletion of every Podman VM
[macos]
clean: clean-vscode clean-nix clean-builder clean-homebrew clean-podman

# Run the Linux Nix cleanup
[linux]
clean: clean-nix

# Run Nix's one-day profile cleanup for the user and system, then optimise
clean-nix:
    nix-collect-garbage --delete-older-than 1d
    sudo -H "$(command -v nix-collect-garbage)" --delete-older-than 1d
    sudo "$(command -v nix-store)" --optimise

# Collect unreachable store paths in the Linux builder now
[macos]
clean-builder:
    sudo ssh -o BatchMode=yes linux-builder nix-store --gc

# Delete every macOS Podman VM, its disk and its matching Docker context
[macos]
clean-podman: podman-delete

# Clear only VS Code caches, including webview resource and updater caches
[macos]
clean-vscode:
    #!/usr/bin/env bash
    set -eu
    status=0
    pgrep -f '[V]isual Studio Code.app/Contents/|[C]ode Helper|[c]om.microsoft.VSCode.ShipIt' >/dev/null || status=$?
    [[ "$status" == 1 ]] || { echo 'Quit VS Code and its updater before clearing caches.' >&2; exit 1; }
    code="$HOME/Library/Application Support/Code"
    rm -rf -- "$code/Cache" "$code/Code Cache" "$code/GPUCache" "$code/CachedData" \
        "$code"/WebStorage/*/CacheStorage "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt"

# Clear Homebrew caches
[macos]
clean-homebrew:
    /opt/homebrew/bin/brew cleanup --prune=all

# Create if necessary and start a macOS Podman VM and its Docker context
[macos]
podman-create mode="rootless":
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
[macos]
podman-delete:
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
    sudo env NIX_CONFIG="$(cat nix.conf)" nix run .#darwin-rebuild -- switch --flake .#legendre

switch-ubuntu-dev:
    nix run .#home-manager -- switch --flake .#ubuntu-dev

switch-ubuntu-system:
    nix run .#system-manager -- switch --flake .#ubuntu-dev --sudo

switch-ubuntu: switch-ubuntu-system switch-ubuntu-dev
