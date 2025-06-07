{ pkgs, ... }:
{
  imports = [
    ../../home-manager/home.nix
  ];
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.05";
    packages = with pkgs; [ cowsay ];
  };
}
