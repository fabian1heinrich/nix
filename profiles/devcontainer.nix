# Standard devcontainer profile
{ ... }:
{
  imports = [
    ./base.nix
    ../home-manager/stacks/development.nix
  ];
}
