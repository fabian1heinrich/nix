# Coding workflow: editors, VCS, Nix maintenance, and AI assistants.
{ pkgs, ... }:
{
  imports = [
    ../programs/codex.nix
    ../programs/direnv.nix
    ../programs/gh.nix
    ../programs/git.nix
    ../programs/just.nix
    ../programs/nh.nix
    ../programs/vscode
    ../programs/zed.nix
    ../programs/worktrunk.nix
  ];

  home.packages = with pkgs; [
    httpie # HTTP client
    lazygit # Git TUI
    nixd # Nix language server
    nixfmt # Nix formatter
    opencode # AI coding agent
    opentofu # Infrastructure as Code tool
    shellcheck # Shell script linter
    worktrunk # Git worktree manager
  ];
}
