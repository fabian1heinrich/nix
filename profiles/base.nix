# Shared baseline used by all profiles
{ ... }:
{
  imports = [
    ../home-manager/default.nix
    ../home-manager/home.nix
    ../home-manager/programs/fzf.nix
    ../home-manager/programs/lsd.nix
    ../home-manager/programs/starship.nix
    ../home-manager/programs/zoxide.nix
    ../home-manager/programs/zsh.nix
  ];
}
