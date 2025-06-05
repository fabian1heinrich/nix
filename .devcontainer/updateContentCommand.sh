#!/bin/bash
# install nix
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes
source /home/vscode/.nix-profile/etc/profile.d/nix.sh && nix --version

# install devcontainer-minimal
export NIX_CONF_DIR=${PWD}
arch=$(uname -m)
if [[ $arch == aarch64 ]]; then
    nix run nixpkgs#home-manager -- switch --flake .#devcontainer-minimal-aarch64-linux
elif [[ $arch == x86_64 ]]; then
    nix run nixpkgs#home-manager -- switch --flake .#devcontainer-x86_64-linux
fi
