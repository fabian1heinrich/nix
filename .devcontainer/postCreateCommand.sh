#!/bin/bash
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes
source /home/vscode/.nix-profile/etc/profile.d/nix.sh && nix --version
