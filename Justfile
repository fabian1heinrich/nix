set shell := ["bash", "-uc"]

docker := "env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION -u DOCKER_CONTEXT docker"

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

# Show the current macOS machine or Ubuntu rootless Podman status.
container-status:
    @case "$(uname -s)" in \
        Darwin) \
            podman machine list; \
            context=podman; \
            ;; \
        Linux) \
            podman info --format=json | \
                jq -r '"Podman rootless: version=\(.version.Version) graphRoot=\(.store.graphRoot)"'; \
            if rootful_info="$(sudo -n podman info --format=json 2>/dev/null)"; then \
                jq -nr --argjson info "$rootful_info" \
                    '"Podman rootful: version=\($info.version.Version) graphRoot=\($info.store.graphRoot)"'; \
            else \
                echo 'Podman rootful: run sudo podman info to inspect'; \
            fi; \
            context=podman-rootless; \
            ;; \
        *) \
            echo 'Unsupported operating system' >&2; \
            exit 1; \
            ;; \
    esac; \
    info="$({{ docker }} --context "$context" info 2>&1)" && printf '%s\n' "$info" || \
        echo 'Docker API unavailable; run ctx-podman to start it.'

# Reset the macOS Podman machine or Ubuntu rootless Podman storage.
container-reset:
    @case "$(uname -s)" in \
        Darwin) podman machine reset --force ;; \
        Linux) podman system reset --force ;; \
        *) echo 'Unsupported operating system' >&2; exit 1 ;; \
    esac

# Prune the current macOS machine mode or Ubuntu rootless storage.
container-prune:
    @podman system prune

# Remove all containers and data from the current macOS mode or Ubuntu rootless storage.
container-clean-all:
    @podman container rm --all --force --volumes
    @podman system prune --all --volumes --force
