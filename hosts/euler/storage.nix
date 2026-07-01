{
  config,
  lib,
  ...
}:
{
  options.euler.installDisk = lib.mkOption {
    type = lib.types.str;
    default = "/dev/euler-install-disk";
    description = "Disk device used by disko when preparing the Euler install target.";
  };

  config = {
    disko.devices = import ./storage-layout.nix {
      disk = config.euler.installDisk;
    };

    boot.initrd.services.lvm.enable = true;
  };
}
