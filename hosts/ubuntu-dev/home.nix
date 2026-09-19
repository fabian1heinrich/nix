{
  pkgs,
  ...
}:
{
  imports = [
    ../../home-manager/profiles/workstation.nix
    ./podman.nix
    ./ubuntu.nix
  ];

  home = {
    packages = with pkgs; [
      # Container & virtualization
      ctop
      kind
      libvirt
      qemu
      vcluster
      virt-manager
      virtiofsd

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
