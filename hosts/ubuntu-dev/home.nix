{
  pkgs,
  qemuPkgs ? pkgs,
  userConfig,
  ...
}:
{
  imports = [
    ../../profiles/desktop-linux.nix
    ./ubuntu.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # AI tools
      codex

      # Container & virtualization
      colima
      ctop
      docker-buildx
      docker-client
      docker-compose
      kind
      qemuPkgs.qemu
      virt-manager

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
