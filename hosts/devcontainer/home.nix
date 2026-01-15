{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/cli-common.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      cowsay
    ];
  };
}
