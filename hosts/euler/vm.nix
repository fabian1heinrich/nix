{ lib, ... }:
{
  imports = [
    ./nixos.nix
    ./storage.nix
  ];

  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_scsi"
  ];

  networking.hostName = "euler";
  euler.installDisk = "/dev/vda";
}
