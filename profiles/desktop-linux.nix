# Linux desktop profile
{ ... }:
{
  imports = [
    ./common.nix
    ../home-manager/programs/broot.nix
    ../home-manager/programs/claude-code.nix
    ../home-manager/programs/codex.nix
    ../home-manager/programs/gh.nix
    ../home-manager/programs/ghostty.nix
    ../home-manager/programs/git.nix
    ../home-manager/programs/mcfly.nix
    ../home-manager/programs/mcp.nix
    ../home-manager/programs/navi.nix
    ../home-manager/programs/nh.nix
    ../home-manager/programs/tmux.nix
    ../home-manager/programs/yazi.nix
  ];
}
