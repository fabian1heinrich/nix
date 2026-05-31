set shell := ["bash", "-uc"]

os := `uname -s`
cluster := env("KIND_CLUSTER", "dev")
podman_rootless_machine := env("PODMAN_ROOTLESS_MACHINE", "podman-machine-default")
podman_rootful_machine := env("PODMAN_ROOTFUL_MACHINE", "podman-machine-rootful")

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-check:
    nix flake check --all-systems --no-build

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

podman-up:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-up-rootless

podman-up-rootless machine=podman_rootless_machine:
    case "{{ os }}" in \
      Darwin) \
        running="$(podman machine list --format json | jq -r --arg machine "{{ machine }}" '.[] | select(.Name == $machine) | .Running' | head -n1)"; \
        if [[ "$running" == "true" ]]; then \
          true; \
        elif [[ "$running" == "false" ]]; then \
          podman machine start "{{ machine }}"; \
        else \
          podman machine init --now "{{ machine }}"; \
        fi ;; \
      Linux) systemctl --user start podman.socket || true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-up-rootful machine=podman_rootful_machine:
    case "{{ os }}" in \
      Darwin) \
        running="$(podman machine list --format json | jq -r --arg machine "{{ machine }}" '.[] | select(.Name == $machine) | .Running' | head -n1)"; \
        if [[ "$running" == "true" ]]; then \
          true; \
        elif [[ "$running" == "false" ]]; then \
          podman machine start "{{ machine }}"; \
        else \
          podman machine init --rootful --now "{{ machine }}"; \
        fi ;; \
      *) echo "Rootful Podman machine recipes are only supported on macOS" >&2; exit 1 ;; \
    esac
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-env "{{ machine }}"

podman-env machine=podman_rootful_machine:
    @case "{{ os }}" in \
      Darwin) \
        socket="$HOME/.tmp/podman/{{ machine }}-api.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export PODMAN_MACHINE=%q\n" "{{ machine }}"; \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      Linux) \
        socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-down:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-down-rootless

podman-down-rootless machine=podman_rootless_machine:
    case "{{ os }}" in \
      Darwin) podman machine stop "{{ machine }}" ;; \
      Linux) systemctl --user stop podman.socket || true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-down-rootful machine=podman_rootful_machine:
    case "{{ os }}" in \
      Darwin) podman machine stop "{{ machine }}" ;; \
      *) echo "Rootful Podman machine recipes are only supported on macOS" >&2; exit 1 ;; \
    esac

podman-machines:
    podman machine list

podman-reset:
    case "{{ os }}" in \
      Darwin) podman machine reset ;; \
      *) echo "Podman machine reset is only supported on macOS" >&2; exit 1 ;; \
    esac

podman-status:
    podman info

podman-prune:
    podman system prune

podman-clean-all:
    podman container stop --all || true
    podman pod rm --all --force || true
    podman container rm --all --force --volumes || true
    podman secret rm --all --ignore || true
    podman volume rm --all --force || true
    podman image rm --all --force --ignore || true
    podman system prune --all --build --volumes --force
    podman image prune --all --build-cache --force || true
    podman network prune --force || true
    case "{{ os }}" in \
      Darwin) podman machine ssh sudo fstrim -av || true ;; \
      Linux) true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac
