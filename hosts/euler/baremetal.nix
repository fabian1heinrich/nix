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
  boot.loader.timeout = lib.mkDefault 5;

  hardware = {
    enableRedistributableFirmware = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  };

  networking.hostName = "euler";
  euler.installDisk = "/dev/sda";

  specialisation = {
    nvidia-closed.configuration = {
      system.nixos.tags = [ "nvidia-closed" ];
      hardware.nvidia.open = lib.mkForce false;
    };

    console-rescue.configuration = {
      system.nixos.tags = [ "console-rescue" ];
      systemd.defaultUnit = lib.mkForce "multi-user.target";
      services = {
        displayManager.gdm.enable = lib.mkForce false;
        desktopManager.gnome.enable = lib.mkForce false;
        xserver.enable = lib.mkForce false;
      };
    };
  };
}
