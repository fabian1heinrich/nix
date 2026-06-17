{ disk }:
{
  disk.euler = {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        "euler-boot" = {
          type = "EF00";
          size = "1024M";
          label = "euler-boot";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [
              "-n"
              "boot"
            ];
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        "euler-luks" = {
          size = "100%";
          label = "euler-luks";
          content = {
            type = "luks";
            name = "euler-crypt";
            extraFormatArgs = [
              "--type"
              "luks2"
            ];
            content = {
              type = "lvm_pv";
              vg = "euler";
            };
          };
        };
      };
    };
  };

  lvm_vg.euler = {
    type = "lvm_vg";
    lvs.root = {
      size = "100%";
      content = {
        type = "filesystem";
        format = "ext4";
        extraArgs = [
          "-L"
          "nixos"
        ];
        mountpoint = "/";
      };
    };
  };
}
