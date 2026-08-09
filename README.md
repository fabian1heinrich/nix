# Nix Configuration

Personal Nix setup for macOS (`legendre`) and Linux (`ubuntu-dev`).

## Bootstrap

Prerequisites:

- Nix with flakes enabled
- Git
- On macOS: administrator access and the Xcode command line tools
- On Ubuntu: a user named `ubuntu-dev`, or adjust `flake.nix`

The `legendre` Darwin configuration checks that the Xcode Command Line Tools
are installed and keeps `xcode-select` pointed at
`/Library/Developer/CommandLineTools`. Full Xcode is intentionally not managed
by this flake; remove `Xcode.app` manually if it is installed and you do not
need the IDE, simulators, or platform SDK GUI tooling.

From a fresh checkout, enter the repo and use the matching first-run command
below. The repo includes `nix.conf` so the bootstrap commands can enable flakes
before the managed configuration takes over.

## Structure

- `profiles/base.nix`: minimal shared baseline
- `profiles/desktop.nix`: shared desktop baseline
- `home-manager/stacks/*.nix`: workflow bundles
- `hosts/<name>/home.nix`: host-specific additions

Hosts compose local profiles and role stacks.

## Apply

macOS (`legendre`, first bootstrap):

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#legendre
```

macOS (`legendre`, regular updates):

```bash
sudo darwin-rebuild switch --flake .#legendre
```

Homebrew app updates are intentionally kept out of `darwin-rebuild` activation so rebuilds stay fast and predictable. Run them explicitly when you want to update Homebrew-managed apps:

```bash
brew update
brew upgrade
brew upgrade --cask
brew upgrade --cask --greedy
mas upgrade
```

Ubuntu (`ubuntu-dev`, first run):

```bash
export NIX_CONF_DIR=$(pwd)
nix run github:nix-community/home-manager -- switch --flake .#ubuntu-dev
```

Ubuntu (`ubuntu-dev`, after setup):

```bash
home-manager switch --flake .#ubuntu-dev
```

## Dev Shells

```bash
nix develop
```

## Project-local Podman

Create or update a local `podman` Docker context once on each host:

```bash
case "$(uname -s)" in
  Darwin)
    machine="${PODMAN_MACHINE:-podman-machine-default}"
    docker_host="unix://$(podman machine inspect \
      --format '{{.ConnectionInfo.PodmanSocket.Path}}' "$machine")"
    ;;
  Linux)
    docker_host="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
    ;;
esac

if docker context inspect podman >/dev/null 2>&1; then
  docker context update podman --docker "host=$docker_host"
else
  docker context create podman --description Podman --docker "host=$docker_host"
fi
```

Projects select that context without changing Docker's persisted global
selection. Add this to each project's `.envrc`:

```bash
unset DOCKER_HOST
export DOCKER_CONTEXT=podman
```

Then run `direnv allow`. The Linux rootless API socket targeted by the context
is managed by Home Manager. On macOS, start the selected machine with
`podman machine start "${PODMAN_MACHINE:-podman-machine-default}"`; its rootful
or rootless mode is a property of that machine. Use `sudo podman` or
`sudo podman compose` for rootful containers on Linux.

## Checks

Fast evaluation check:

```bash
just nix-check
```

Format and script checks:

```bash
just nix-fmt
nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck
```

Native build checks are exposed as flake checks on their matching platform:

- macOS: `checks.aarch64-darwin.legendre-system-build`
- Ubuntu: `checks.x86_64-linux.ubuntu-dev-activation-build`

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
