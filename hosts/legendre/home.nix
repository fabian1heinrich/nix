{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/desktop-darwin.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # Terminal emulators
      alacritty

      # AI tools
      chatgpt
      codex
      opencode

      # Container & virtualization
      colima
      docker-buildx
      docker-client
      docker-compose
      docker-credential-helpers
      kind
      utm

      # Communication
      discord
      slack
      zoom-us

      # Productivity
      bitwarden-desktop
      flashspace

      # System tools
      openvpn
      yubikey-manager

      uv
      nodejs_24
    ];
  };
}
