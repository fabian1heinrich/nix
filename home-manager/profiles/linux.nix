# Linux additions for the portable workstation environment.
{ ... }:
{
  imports = [
    ./workstation.nix
    ../stacks/networking.nix
  ];
}
