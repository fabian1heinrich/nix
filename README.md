# Nix Configuration

Personal Nix setup for:

- macOS (`nix-darwin`): `legendre`
- Linux (`home-manager`): `ubuntu-dev`
- Devcontainers: `devcontainer`, `k8s-devcontainer`

## Structure

- `profiles/base.nix`: shared baseline and common tooling
- `profiles/desktop.nix`: desktop module imports shared by macOS and Linux
- `profiles/desktop-darwin.nix`: macOS desktop
- `profiles/desktop-linux.nix`: Linux desktop
- `profiles/devcontainer.nix`: standard devcontainer
- `profiles/k8s-devcontainer.nix`: K8s-focused devcontainer
- `home-manager/default.nix`: shared package set for non-minimal profiles
- `hosts/<name>/home.nix`: host-specific additions

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

Ubuntu (`ubuntu-dev`, first run):

```bash
export NIX_CONF_DIR=$(pwd)
nix run github:nix-community/home-manager -- switch --flake .#ubuntu-dev
```

Ubuntu (`ubuntu-dev`, after setup):

```bash
home-manager switch --flake .#ubuntu-dev
```

Devcontainer (`devcontainer`, first run):

```bash
nix run github:nix-community/home-manager -- switch --flake .#devcontainer
```

Devcontainer (`devcontainer`, after setup):

```bash
home-manager switch --flake .#devcontainer
```

K8s devcontainer (`k8s-devcontainer`, first run):

```bash
nix run github:nix-community/home-manager -- switch --flake .#k8s-devcontainer
```

K8s devcontainer (`k8s-devcontainer`, after setup):

```bash
home-manager switch --flake .#k8s-devcontainer
```

## Common Commands

```bash
nix flake update
nix fmt
nix flake check
```

`nix flake check` evaluates all declared targets (`legendre`, `ubuntu-dev`, `devcontainer`, `k8s-devcontainer`), and CI runs it on every push and pull request.

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
