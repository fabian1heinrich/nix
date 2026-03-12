# Nix Configuration

Personal Nix setup for:

- macOS (`nix-darwin`): `legendre`
- Linux (`home-manager`): `ubuntu-dev`
- Devcontainers: `devcontainer`, `k8s-devcontainer`

## Structure

- `profiles/common.nix`: shared baseline and common tooling
- `profiles/desktop-darwin.nix`: macOS desktop
- `profiles/desktop-linux.nix`: Linux desktop
- `profiles/devcontainer.nix`: standard devcontainer
- `profiles/k8s-devcontainer.nix`: K8s-focused devcontainer
- `home-manager/default.nix`: shared package set for non-minimal profiles
- `hosts/<name>/home.nix`: host-specific additions

## Apply

macOS (first run):

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin -- switch --flake .#legendre
```

macOS (after setup):

```bash
sudo darwin-rebuild switch --flake .#legendre
```

Ubuntu:

```bash
export NIX_CONF_DIR=$(pwd)
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

Devcontainer:

```bash
nix run nixpkgs#home-manager -- switch --flake .#devcontainer
```

K8s devcontainer:

```bash
nix run nixpkgs#home-manager -- switch --flake .#k8s-devcontainer
```

## Common Commands

```bash
nix flake update
nix fmt
nix flake check
```

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
