{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.05";
    packages = with pkgs; [
      cowsay
    ];
  };
}
