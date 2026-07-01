{ config, lib, ... }:
let
  hasHardwareConfiguration = builtins.pathExists ./hardware-configuration.nix;
in
{
  imports = [
    ./nixos.nix
    ./storage.nix
  ]
  ++ lib.optionals hasHardwareConfiguration [
    ./hardware-configuration.nix
  ];

  # First-install defaults. Replace them by committing the generated
  # hardware-configuration.nix from the actual machine after the first boot.
  boot.initrd.availableKernelModules = lib.mkDefault [
    "ahci"
    "nvme"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];

  hardware = {
    enableRedistributableFirmware = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  };

  networking.hostName = "euler";

  # Enable and fill this in for a static wired address.
  # networking.networkmanager.ensureProfiles.profiles.euler-wired = {
  #   connection = {
  #     id = "euler-wired";
  #     type = "ethernet";
  #     interface-name = "enp5s0";
  #     autoconnect = true;
  #   };
  #
  #   ipv4 = {
  #     method = "manual";
  #     addresses = "192.168.1.50/24";
  #     gateway = "192.168.1.1";
  #     dns = "1.1.1.1;8.8.8.8;";
  #     dns-search = "home.arpa;";
  #     ignore-auto-dns = "true";
  #   };
  #
  #   ipv6 = {
  #     method = "auto";
  #     addr-gen-mode = "stable-privacy";
  #   };
  # };

  euler.installDisk = "/dev/sda";
}
