# Shared baseline used by all profiles.
{ ... }:
{
  imports = [
    ../default.nix
    ../home.nix
    ../programs/fzf.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
  ];
}
