{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/desktop.nix
    ../../home-manager/stacks/development.nix
    ../../home-manager/stacks/kubernetes.nix
    ../../home-manager/programs/bitwarden-secrets.nix
    ../../home-manager/programs/mcp.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # CLI tools
      opencode

      # Container & virtualization
      kind

      # System tools
      openvpn
      yubikey-manager
    ];
  };

  programs.codex.package = null;
}
