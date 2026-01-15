# Linux desktop configuration profile
# Extends cli-common with Linux-specific programs
{ ... }:
{
  imports = [
    ./cli-common.nix
    ../home-manager/programs/ghostty.nix
    ../home-manager/programs/mcfly.nix
    ../home-manager/programs/navi.nix
  ];
}
