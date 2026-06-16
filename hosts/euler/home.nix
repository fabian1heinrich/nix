{
  pkgs,
  userConfig,
  ...
}:
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
      # Desktop tools
      bitwarden-desktop
      cowsay
      ghostty
      google-chrome
      vscode
      wl-clipboard
      xclip

      # Container & virtualization
      cloud-provider-kind
      ctop
      kind
      podman
      podman-compose

      # Infrastructure as Code (IaC)
      opentofu
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
    };
  };
}
