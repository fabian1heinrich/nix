# Extended CLI tools for full development workstations
# Includes additional tools like broot, tmux, yazi
{ ... }:
{
  imports = [
    ./cli-common.nix
    ../home-manager/programs/broot.nix
    ../home-manager/programs/tmux.nix
    ../home-manager/programs/yazi.nix
  ];
}
