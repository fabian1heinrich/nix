# Shared desktop baseline used by both macOS and Linux desktops.
{ ... }:
{
  imports = [
    ./base.nix
    ../home-manager/stacks/terminal.nix
  ];
}
