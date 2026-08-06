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

container-status:
    @podman machine list 2>/dev/null || true
    @info="$({{ docker }} info 2>&1)" && printf '%s\n' "$info" || echo "Docker API unavailable; run ctx-podman to start it."

container-reset:
    podman machine reset --force

container-prune:
    @podman system prune

container-clean-all:
    @podman container rm --all --force --volumes
    @podman system prune --all --volumes --force
