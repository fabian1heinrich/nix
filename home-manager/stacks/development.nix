# Coding workflow: editors, VCS, Nix maintenance, and AI assistants.
{ pkgs, ... }:
{
  imports = [
    ../programs/claude-code.nix
    ../programs/codex.nix
    ../programs/direnv.nix
    ../programs/gh.nix
    ../programs/git.nix
    ../programs/lazyworktree.nix
    ../programs/nh.nix
    ../programs/worktrunk.nix
  ];

  home.packages = with pkgs; [
    httpie # HTTP client
    lazygit # Git TUI
    shellcheck # Shell script linter
  ];
}
