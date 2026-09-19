{ pkgs, ... }:
{
  imports = [
    ../../home-manager/profiles/workstation.nix
    ../../home-manager/programs/snapzy.nix
  ];

  home.packages = with pkgs; [
    # CLI tools
    opencode

    # Container & virtualization
    kind
    cloud-provider-kind

    # System tools
    openvpn
  ];

}
