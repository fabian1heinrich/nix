{ lib, pkgs, ... }:
{
  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
  home.shell.enableZshIntegration = true;
  nix = {
    package = lib.mkDefault pkgs.nix;
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
