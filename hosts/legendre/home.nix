{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/darwin-desktop.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;
    stateVersion = "25.11";

    packages = with pkgs; [
      # Terminal emulators
      alacritty

      # AI tools
      chatgpt
      claude-code
      codex
      opencode

      # Container & virtualization
      colima
      docker-buildx
      docker-client
      docker-compose
      docker-credential-helpers
      utm

      # Communication
      discord
      slack
      zoom-us

      # Productivity
      bitwarden-desktop
      flashspace
      zotero

      # System tools
      openvpn
      yubikey-manager
    ];
  };
}
