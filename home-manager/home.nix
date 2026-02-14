{ lib, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.shell.enableZshIntegration = true;
  home.stateVersion = lib.mkDefault "25.11";
  nix = {
    package = lib.mkDefault pkgs.nix;
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
