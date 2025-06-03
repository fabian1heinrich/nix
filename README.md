# NIX

```bash
export NIX_USER_CONF_FILES=configuration.nix
```

## DevContainer

```bash
nix run nixpkgs#home-manager -- switch --flake .#devcontainer-aarch64-linux
# nix run nixpkgs#home-manager -- switch --flake .#devcontainer-x86_64-linux
```

## Darwin

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### install homebrew

```bash
/bin/bash -c "$(curl -fsSL <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>)"
```

### nix-darwin

```bash
nix run nix-darwin -- switch --flake .#legendre
```

nix flake update --flake .
