{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.11";
    packages = with pkgs; [
      cowsay
    ];
  };
}
