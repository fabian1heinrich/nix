set shell := ["bash", "-uc"]

os := `uname -s`
cluster := env("KIND_CLUSTER", "dev")
docker := "env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION -u DOCKER_CONTEXT docker"

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-check:
    nix flake check --all-systems --no-build

nix-shellcheck:
    nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck

nix-fmt:
    nix fmt

nix-update:
    nix flake update

switch-legendre:
    sudo darwin-rebuild switch --flake .#legendre

switch-ubuntu-dev:
    home-manager switch --flake .#ubuntu-dev

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

kind-up cluster=cluster:
    case "{{ os }}" in \
      Darwin) KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name {{ cluster }} ;; \
      Linux) systemd-run --scope --user -p "Delegate=yes" kind create cluster --name {{ cluster }} ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

kind-down cluster=cluster:
    kind delete cluster --name {{ cluster }}

kind-list:
    kind get clusters

kind-load image cluster=cluster:
    kind load docker-image {{ image }} --name {{ cluster }}

kind-kubeconfig cluster=cluster:
    kind export kubeconfig --name {{ cluster }}

k9s cluster=cluster:
    k9s --context kind-{{ cluster }}

colima-context profile="":
    @container-context colima "{{ profile }}"

container-vms:
    @colima list || true
    @podman machine list || true

container-vms-delete-all-macos:
    @case "{{ os }}" in \
      Darwin) ;; \
      *) echo "This recipe only deletes macOS Colima/Podman VMs." >&2; exit 1 ;; \
    esac
    @if command -v colima >/dev/null 2>&1; then \
      colima list --json 2>/dev/null | jq -r 'if type == "array" then .[] elif type == "object" then . else empty end | .name // empty' | \
        while IFS= read -r profile; do \
          [[ -n "$profile" ]] || continue; \
          colima delete --force "$profile"; \
          if [[ "$profile" == "default" ]]; then context="colima"; else context="colima-$profile"; fi; \
          {{ docker }} context rm --force "$context" >/dev/null 2>&1 || true; \
        done; \
    fi
    @if command -v podman >/dev/null 2>&1; then \
      podman machine list --format json 2>/dev/null | jq -r '.[] | .Name // empty' | \
        while IFS= read -r machine; do \
          [[ -n "$machine" ]] || continue; \
          podman machine rm --force "$machine"; \
        done; \
      {{ docker }} context rm --force podman podman-root podman-rootless podman-rootful >/dev/null 2>&1 || true; \
    fi

container-colima-delete profile="default" context="colima":
    colima delete --force "{{ profile }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-colima-delete-data profile="default" context="colima":
    colima delete --force --data "{{ profile }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-podman-delete machine="podman-machine-default" context="podman-rootless":
    podman machine rm --force "{{ machine }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-podman-reset:
    podman machine reset --force
    @{{ docker }} context rm --force podman podman-root podman-rootless podman-rootful 2>/dev/null || true

container-status:
    @{{ docker }} info

container-prune:
    @{{ docker }} system prune

container-clean-all:
    @containers="$({{ docker }} container ls -aq)"; \
      if [[ -n "$containers" ]]; then \
        {{ docker }} container rm --force --volumes $containers; \
      fi
    @{{ docker }} system prune --all --volumes --force
    @{{ docker }} builder prune --all --force || true
    @{{ docker }} network prune --force || true
