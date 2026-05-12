# Nix Configuration

Personal Nix setup for macOS (`legendre`) and Linux (`ubuntu-dev`).

## Structure

- `profiles/base.nix`: minimal shared baseline
- `profiles/desktop.nix`: shared desktop baseline
- `home-manager/stacks/*.nix`: reusable workflow bundles
- `hosts/<name>/home.nix`: host-specific additions

Hosts compose small role stacks. Reusable Home Manager modules are exported as
`homeManagerModules`.

## External Consumers

Add this repo as a flake input:

```nix
inputs.fabian-nix.url = "github:fabianheinrich/nix";
```

### Home Manager Devcontainers

For devcontainers, compose `homeManagerModules` directly. Do not import
`homeConfigurations.ubuntu-dev`; it includes desktop and machine-specific config.
Start with `profiles.base`, add only the needed stacks, then build and activate
the resulting Home Manager activation package as the container user. For mutable
containers, run activation at startup or switch the flake from inside the
container.

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
nix develop .#kubernetes
```

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
