{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = lib.mkForce "";

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    qemuGuest.enable = true;
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  proxmox = {
    qemuConf = {
      name = "nixos-cloud-template";
      cores = 2;
      memory = 2048;
      bios = "ovmf";
      scsihw = "virtio-scsi-single";
    };

    qemuExtraConf = {
      cpu = "host";
    };

    cloudInit = {
      enable = true;
      defaultStorage = "local-lvm";
    };
  };

  system.stateVersion = "25.11";
}
