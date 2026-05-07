# Nix Configuration

Personal Nix setup for:

- macOS (`nix-darwin`): `legendre`
- Linux (`home-manager`): `ubuntu-dev`

## Structure

- `profiles/base.nix`: minimal shared baseline
- `profiles/desktop.nix`: shared desktop baseline
- `home-manager/stacks/*.nix`: reusable workflow bundles for terminal, development, containers, and Kubernetes
- `hosts/<name>/home.nix`: host-specific additions

Hosts compose small role stacks; `homeManagerModules` is exported for external flake consumers.

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

## Common Commands

```bash
just --list
just check
just fmt
```

Equivalent direct commands:

```bash
nix flake update
nix fmt
nix flake check --all-systems --no-build
```

## Dev Shells

```bash
nix develop
nix develop .#kubernetes
```

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
