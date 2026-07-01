{
  eulerDisk ? "/dev/euler-install-disk",
  ...
}:
{
  disko.devices = import ./storage-layout.nix {
    disk = eulerDisk;
  };
}
