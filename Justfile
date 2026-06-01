set shell := ["bash", "-uc"]

os := `uname -s`
cluster := env("KIND_CLUSTER", "dev")
podman_rootless_machine := env("PODMAN_ROOTLESS_MACHINE", "podman-machine-default")
podman_rootful_machine := env("PODMAN_ROOTFUL_MACHINE", "podman-machine-rootful")
podman_rootless_context := env("PODMAN_ROOTLESS_CONTEXT", "podman-rootless")
podman_rootful_context := env("PODMAN_ROOTFUL_CONTEXT", "podman-rootful")
podman_ubuntu_dev_rootful_context := env("PODMAN_UBUNTU_DEV_ROOTFUL_CONTEXT", "ubuntu-dev-rootful")

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
      Linux) \
        socket="/run/podman/podman.sock"; \
        if [[ ! -S "$socket" ]]; then \
          if systemctl cat podman.socket >/dev/null 2>&1; then \
            sudo systemctl start podman.socket; \
          else \
            podman_bin="$(readlink -f "$(command -v podman)")"; \
            sudo install -d -m 0755 /run/podman; \
            sudo systemctl stop podman-rootful-api.service >/dev/null 2>&1 || true; \
            sudo rm -f "$socket"; \
            sudo systemd-run --unit=podman-rootful-api --collect --property=Restart=on-failure "$podman_bin" system service --time=0 "unix://$socket"; \
          fi; \
          for _ in {1..50}; do \
            [[ -S "$socket" ]] && break; \
            sleep 0.1; \
          done; \
        fi; \
        if [[ -S "$socket" ]]; then \
          sudo chgrp "$(id -gn)" "$socket"; \
          sudo chmod 0660 "$socket"; \
        fi ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-env-rootful "{{ machine }}"

podman-env machine=podman_rootful_machine:
    @case "{{ os }}" in \
      Darwin) \
        socket="$HOME/.tmp/podman/{{ machine }}-api.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export PODMAN_MACHINE=%q\n" "{{ machine }}"; \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      Linux) \
        socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-env-rootful machine=podman_rootful_machine:
    @case "{{ os }}" in \
      Darwin) \
        socket="$HOME/.tmp/podman/{{ machine }}-api.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export PODMAN_MACHINE=%q\n" "{{ machine }}"; \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      Linux) \
        socket="/run/podman/podman.sock"; \
        if [[ -S "$socket" ]]; then \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
        else \
          echo "Rootful Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-context:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-context-rootless

podman-context-rootless context=podman_rootless_context machine=podman_rootless_machine:
    case "{{ os }}" in \
      Darwin) \
        just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-up-rootless "{{ machine }}" >/dev/null; \
        socket="$HOME/.tmp/podman/{{ machine }}-api.sock" ;; \
      Linux) \
        systemctl --user start podman.socket || true; \
        socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock" ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac; \
    if [[ -S "$socket" ]]; then \
      podman system connection remove "{{ context }}" >/dev/null 2>&1 || true; \
      podman system connection add --default "{{ context }}" "unix://$socket"; \
      printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
      printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
      printf "export CONTAINER_CONNECTION=%q\n" "{{ context }}"; \
    else \
      echo "Podman API socket not found: $socket" >&2; \
      exit 1; \
    fi

podman-context-rootful context=podman_rootful_context machine=podman_rootful_machine:
    case "{{ os }}" in \
      Darwin) \
        just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-up-rootful "{{ machine }}" >/dev/null; \
        socket="$HOME/.tmp/podman/{{ machine }}-api.sock" ;; \
      Linux) \
        just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-up-rootful "{{ machine }}" >/dev/null; \
        socket="/run/podman/podman.sock" ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac; \
    if [[ -S "$socket" ]]; then \
      podman system connection remove "{{ context }}" >/dev/null 2>&1 || true; \
      podman system connection add --default "{{ context }}" "unix://$socket"; \
      printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
      printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
      printf "export CONTAINER_CONNECTION=%q\n" "{{ context }}"; \
    else \
      echo "Rootful Podman API socket not found: $socket" >&2; \
      exit 1; \
    fi

podman-context-ubuntu-dev-rootful context=podman_ubuntu_dev_rootful_context:
    case "{{ os }}" in \
      Linux) \
        just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" podman-up-rootful >/dev/null; \
        socket="/run/podman/podman.sock"; \
        if [[ -S "$socket" ]]; then \
          podman system connection remove "{{ context }}" >/dev/null 2>&1 || true; \
          podman system connection add --default "{{ context }}" "unix://$socket"; \
          printf "export DOCKER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_HOST=%q\n" "unix://$socket"; \
          printf "export CONTAINER_CONNECTION=%q\n" "{{ context }}"; \
        else \
          echo "Rootful Podman API socket not found: $socket" >&2; \
          exit 1; \
        fi ;; \
      *) echo "ubuntu-dev rootful Podman context is only supported on Linux" >&2; exit 1 ;; \
    esac

podman-connections:
    podman system connection list

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
      Linux) \
        if systemctl cat podman.socket >/dev/null 2>&1; then \
          sudo systemctl stop podman.socket podman.service || true; \
        fi; \
        sudo systemctl stop podman-rootful-api.service >/dev/null 2>&1 || true; \
        sudo rm -f /run/podman/podman.sock || true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
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
