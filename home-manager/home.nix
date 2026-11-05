{
  lib,
  pkgs,
  userConfig,
  ...
}:
{
  programs.home-manager.enable = true;
  home.shell.enableZshIntegration = true;
  home = {
    username = lib.mkDefault userConfig.username;
    homeDirectory = lib.mkDefault userConfig.homeDirectory;
    stateVersion = userConfig.homeStateVersion;
  };

  nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    package = lib.mkDefault pkgs.nix;
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
