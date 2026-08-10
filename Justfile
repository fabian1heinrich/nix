set shell := ["bash", "-uc"]

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

# Show Podman status and the active Docker API.
container-status:
    @case "$(uname -s)" in \
        Darwin) \
            podman machine list; \
            ;; \
        Linux) \
            podman info --format=json | \
                jq -r '"Podman rootless: version=\(.version.Version) graphRoot=\(.store.graphRoot)"'; \
            podman_path="$(command -v podman)"; \
            if rootful_info="$(/usr/bin/sudo -n "$podman_path" info --format=json 2>/dev/null)"; then \
                jq -nr --argjson info "$rootful_info" \
                    '"Podman rootful: version=\($info.version.Version) graphRoot=\($info.store.graphRoot)"'; \
            else \
                echo 'Podman rootful: run podman-rootful info to inspect'; \
            fi; \
            ;; \
        *) \
            echo 'Unsupported operating system' >&2; \
            exit 1; \
            ;; \
    esac; \
    info="$(docker info 2>&1)" && printf '%s\n' "$info" || \
        echo 'Docker API unavailable for the active endpoint.'

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
