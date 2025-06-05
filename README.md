# NIX

<!-- rework home-manager and nix-darwin installation -->

<!-- TODO: switch to stable channels -->
## DevContainer

## Ubuntu

- install with home-manager script (analog to devcontainer)

## MacOS

- use NIX_CONF_DIR=$(pwd) to initialize

```bash
export NIX_USER_CONF_FILES=configuration.nix
```

## Ubuntu Dev

```bash
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

## DevContainer

```bash
nix run nixpkgs#home-manager -- switch --flake .#devcontainer-aarch64-linux
nix run nixpkgs#home-manager -- switch --flake .#devcontainer-x86_64-linux
```

## Darwin

### install homebrew

```bash
/bin/bash -c "$(curl -fsSL <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>)"
```

### nix-darwin

```bash
nix run nix-darwin -- switch --flake .#legendre
```

nix flake update --flake .

##

- hosts
  - legendre
    - home.nix
    - darwin.nix
  - ubuntu-dev
- home-manager
  - programms
    - zsh
    - ...
  - default -> home.nix (import programs, dotfiles etc)

- init with flags
- init with nix run nixpkgs#home-manager -- init --flake .#ubuntu-dev
- afterwards home-manager/darwin only

<https://github.com/nix-darwin/nix-darwin>
<https://github.com/nix-darwin/nix-darwin/archive/release-25.05.tar.gz>
