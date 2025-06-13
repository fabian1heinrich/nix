# Nix

## Dev Container

```bash
export ARCH=$(uname -m)
nix run nixpkgs#home-manager -- switch --flake .#devcontainer-${ARCH}-linux
home-manager switch --flake .#devcontainer-${ARCH}-linux
```

## Ubuntu

### initial setup (install home-manager)

```bash
export NIX_CONF_DIR=$(pwd)
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

### home-manager

```bash
home-manager switch --flake .#ubuntu-dev
```

## MacOS

### install homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### initial setup (install nix-darwin)

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin -- switch --flake .#legendre
```

### darwin-rebuild

```bash
sudo darwin-rebuild switch --flake .#legendre
```
