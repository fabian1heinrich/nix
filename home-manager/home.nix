{ lib, pkgs, ... }:
{
  programs.home-manager.enable = true;
  nix = {
    package = lib.mkDefault pkgs.nix;
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
