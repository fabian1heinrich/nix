set shell := ["bash", "-uc"]

os := `uname -s`
cluster := env_var_or_default("KIND_CLUSTER", "dev")

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
    case "{{ os }}" in \
      Darwin) podman machine start || podman machine init --now ;; \
      Linux) systemctl --user start podman.socket || true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-down:
    case "{{ os }}" in \
      Darwin) podman machine stop ;; \
      Linux) systemctl --user stop podman.socket || true ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

podman-status:
    podman info

podman-prune:
    podman system prune
