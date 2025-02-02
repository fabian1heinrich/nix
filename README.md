# NIX

## install nix

```bash
sh <(curl -L https://nixos.org/nix/install)
export NIX_USER_CONF_FILES=configuration.nix
```

## build devcontainer

```bash
source /home/vscode/.nix-profile/etc/profile.d/nix.sh && nix --version
nix run nixpkgs#home-manager -- switch --flake .#devcontainer-aarch64-linux
# nix run nixpkgs#home-manager -- switch --flake .#devcontainer-aarch64-darwin
```

## build with nix-darwin

### install homebrew

```bash
/bin/bash -c "$(curl -fsSL <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>)"
```

### nix-darwin

```bash
nix run nix-darwin -- switch --flake .#legendre
```
