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
    # Keep MCP disabled in the shared development stack for now. It pulls in
    # nodejs/uv and starts managing editor context server config on every
    # development host; re-enable once that broader rollout is intentional.
    # ../programs/mcp.nix
    ../programs/nh.nix
    ../programs/zed.nix
    ../programs/worktrunk.nix
  ];

  home.packages = with pkgs; [
    httpie # HTTP client
    lazygit # Git TUI
    shellcheck # Shell script linter
  ];
}
