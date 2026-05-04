{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/desktop-darwin.nix
    ../../home-manager/programs/mcp.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # CLI tools
      codex
      opencode

      # Container & virtualization
      kind

      # System tools
      openvpn
      yubikey-manager
    ];
  };

  programs.zsh.shellAliases = {
    docker = "podman";
    "docker-compose" = "podman-compose";
  };
}
