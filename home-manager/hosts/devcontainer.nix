{ pkgs, ... }:
{
  imports = [
    ../programs/fzf.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
    # ../programs/ghostty.nix
  ];
  programs.zsh.enable = true;
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.05";
    packages = with pkgs; [
      nixfmt-rfc-style
      cowsay
    ];
  };
}
