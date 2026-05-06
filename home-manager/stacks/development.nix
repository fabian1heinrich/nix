# Shared developer tooling.
{ pkgs, ... }:
{
  imports = [
    ../programs/lazyworktree.nix
  ];

  home.packages = with pkgs; [
    httpie # HTTP client
    lazygit # Git TUI
  ];
}
