{ lib, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.shell.enableZshIntegration = true;
  home.sessionVariables = {
    TMPDIR = "$HOME/.tmp";
  };
  home.activation.ensureTmpdir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.tmp"
  '';
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
