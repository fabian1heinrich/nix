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
    ./ubuntu.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # AI tools
      codex

      # Container & virtualization
      ctop
      kind
      qemu
      virt-manager
      podman
      podman-compose
      virtiofsd
      gvproxy

      # Infrastructure as Code (IaC)
      opentofu
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
    };
  };

  xdg.configFile."containers/containers.conf".text = ''
    [engine]
    compose_providers = [
      "${pkgs.podman-compose}/bin/podman-compose",
    ]
    helper_binaries_dir = [
      "${pkgs.podman}/libexec/podman",
      "${pkgs.gvproxy}/bin",
    ]
  '';
}
