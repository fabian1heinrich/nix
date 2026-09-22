# Interactive Linux networking and hardware diagnostics.
{ lib, pkgs, ... }:
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      dnsutils
      ethtool
      hwinfo
      iftop
      iperf3
      iw
      lshw
      lsof
      mtr
      netcat-openbsd
      nmap
      pciutils
      socat
      traceroute
      usbutils
      wavemon
    ]
  );
}
