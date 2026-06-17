{
  eulerDisk ? "/dev/disk/by-id/euler-install-disk",
  ...
}:
{
  disko.devices = import ./storage-layout.nix {
    disk = eulerDisk;
  };
}
