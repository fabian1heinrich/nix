{ lib, pkgs, ... }:
{
  programs.nh.enable = true;

  nix.gc = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 1d";
  };
}
