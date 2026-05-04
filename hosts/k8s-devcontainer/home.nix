{ userConfig, ... }:
{
  imports = [
    ../../profiles/k8s-devcontainer.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;
  };
}
