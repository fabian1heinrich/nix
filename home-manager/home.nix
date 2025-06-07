{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;
  nix = {
    package = pkgs.nix;
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
