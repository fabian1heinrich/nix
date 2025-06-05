{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  nix = {
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nix.package = pkgs.nix;
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.11";
    packages = with pkgs; [
      cowsay
      nixfmt-rfc-style
      nixd
    ];
  };
}
