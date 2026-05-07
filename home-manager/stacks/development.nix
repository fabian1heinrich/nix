# Coding workflow: editors, VCS, Nix maintenance, and AI assistants.
{ pkgs, ... }:
{
  imports = [
    ../programs/claude-code.nix
    ../programs/codex.nix
    ../programs/gh.nix
    ../programs/git.nix
    ../programs/lazyworktree.nix
    ../programs/nh.nix
  ];

  home.packages = with pkgs; [
    httpie # HTTP client
    lazygit # Git TUI
  ];
}
