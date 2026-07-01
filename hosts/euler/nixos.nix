{
  lib,
  pkgs,
  userConfig,
  ...
}:
{
  nix = {
    channel.enable = false;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "@wheel"
        userConfig.username
      ];
    };
  };

  boot = {
    loader = {
      timeout = lib.mkDefault 3;
      systemd-boot.enable = lib.mkDefault true;
      systemd-boot.configurationLimit = lib.mkDefault 1;
      efi.canTouchEfiVariables = lib.mkDefault true;
      grub.enable = lib.mkDefault false;
      grub.configurationLimit = lib.mkDefault 1;
      grub.useOSProber = lib.mkDefault false;
    };
  };

  networking = {
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
    };
  };

  console.keyMap = "us";

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    displayManager = {
      defaultSession = "gnome";
      gdm = {
        enable = true;
        wayland = true;
      };
    };
    desktopManager.gnome.enable = true;
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
    pcscd.enable = true;
  };

  programs.zsh.enable = true;

  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.username;
    home = userConfig.homeDirectory;
    initialPassword = "euler";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  system.stateVersion = "25.11";
}
