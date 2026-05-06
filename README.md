# Nix Configuration

Personal Nix setup for:

- macOS (`nix-darwin`): `legendre`
- Linux (`home-manager`): `ubuntu-dev`
- Devcontainers: `devcontainer`, `k8s-devcontainer`

## Structure

- `profiles/base.nix`: minimal shared baseline
- `home-manager/stacks/*.nix`: reusable tool bundles selected by profiles
- `profiles/desktop.nix`: shared desktop profile
- `profiles/devcontainer.nix`: standard devcontainer
- `profiles/k8s-devcontainer.nix`: K8s-focused devcontainer
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
nix flake check --all-systems --no-build
```

`nix flake check --all-systems --no-build` evaluates all declared targets (`legendre`, `ubuntu-dev`, `devcontainer`, `k8s-devcontainer`), and CI runs it on every push and pull request.

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
