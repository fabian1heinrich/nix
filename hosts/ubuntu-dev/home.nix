{
  pkgs,
  ...
}:
{
  imports = [
    ../../home-manager/profiles/gnome.nix
    ./gnome.nix
    ./podman.nix
  ];

  home.packages = with pkgs; [
    # Container & virtualization
    libvirt
    qemu
    virt-manager
    virtiofsd
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_TIME = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
  };
}
