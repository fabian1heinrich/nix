# macOS desktop configuration profile
# Extends cli-extended with macOS-specific programs
{ ... }:
{
  imports = [
    ./cli-extended.nix
    ../home-manager/programs/ghostty.nix
  ];
}
