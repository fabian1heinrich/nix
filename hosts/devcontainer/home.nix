{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/devcontainer.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      cowsay
    ];
  };
}
