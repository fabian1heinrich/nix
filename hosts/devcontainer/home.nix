{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/cli-common.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;
    stateVersion = "25.11";

    packages = with pkgs; [
      cowsay
    ];
  };
}
