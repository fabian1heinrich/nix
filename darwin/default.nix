{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.users.fabian.home = "/Users/fabian";
  imports = [
    ./system.nix
    ./homebrew.nix
  ];
}
