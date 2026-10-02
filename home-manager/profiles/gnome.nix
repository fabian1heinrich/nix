# Complete GNOME workstation environment on Linux.
{ ... }:
{
  imports = [
    ./linux.nix
    ../desktops/gnome.nix
  ];
}
