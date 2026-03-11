# Common CLI tools and shell configuration
# Shared across all hosts (macOS, Linux, devcontainers)
{ ... }:
{
  imports = [
    ../home-manager/home.nix
    ../home-manager/default.nix
    ../home-manager/programs/claude-code.nix
    # ../home-manager/programs/codex.nix
    ../home-manager/programs/fzf.nix
    ../home-manager/programs/git.nix
    ../home-manager/programs/gh.nix
    ../home-manager/programs/k9s.nix
    ../home-manager/programs/kubecolor.nix
    ../home-manager/programs/kubeswitch.nix
    ../home-manager/programs/lazyworktree.nix
    ../home-manager/programs/lsd.nix
    ../home-manager/programs/mcp.nix
    ../home-manager/programs/nh.nix
    ../home-manager/programs/starship.nix
    ../home-manager/programs/zoxide.nix
    ../home-manager/programs/zsh.nix
  ];
}
