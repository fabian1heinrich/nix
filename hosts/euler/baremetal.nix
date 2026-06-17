{ lib, ... }:
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

  networking.hostName = "euler";
}
