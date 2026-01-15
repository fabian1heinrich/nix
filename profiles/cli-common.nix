# Common CLI tools and shell configuration
# Shared across all hosts (macOS, Linux, devcontainers)
{ ... }:
{
  imports = [
    ../home-manager/home.nix
    ../home-manager/default.nix
    ../home-manager/programs/fzf.nix
    ../home-manager/programs/git.nix
    ../home-manager/programs/gh.nix
    ../home-manager/programs/lsd.nix
    ../home-manager/programs/starship.nix
    ../home-manager/programs/zoxide.nix
    ../home-manager/programs/zsh.nix
  ];
}
