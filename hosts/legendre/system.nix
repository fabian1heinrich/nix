{ pkgs, userConfig, ... }:
let
  screenshotDirectory = "${userConfig.homeDirectory}/Downloads/screenshots";
in
{
  nix = {
    enable = true;
    channel.enable = false;
    gc = {
      automatic = true;
      interval = {
        Hour = 3;
        Minute = 15;
      };
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      interval = {
        Hour = 4;
        Minute = 15;
      };
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [ "https://nkl-sofka.cachix.org" ];
      extra-trusted-public-keys = [
        "nkl-sofka.cachix.org-1:hLg9frFNJynrxe7SSBb/p6pbawlpZmG10bw+wLsTufw="
      ];
      trusted-users = [
        "@admin"
        userConfig.username
      ];
    };
  };

  networking = {
    computerName = "legendre";
    hostName = "legendre";
    localHostName = "legendre";
    applicationFirewall = {
      enable = true;
      allowSigned = true;
      allowSignedApp = true;
      enableStealthMode = true;
    };
  };

  time.timeZone = "Europe/Berlin";
  programs.zsh.enable = true;

  users.users.${userConfig.username} = {
    home = userConfig.homeDirectory;
    shell = pkgs.zsh;
  };

  environment = {
    shells = [ pkgs.zsh ];
    systemPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
  };

  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  system = {
    primaryUser = userConfig.username;
    stateVersion = 6;
    activationScripts.screenshotDirectory.text = ''
      install -d -m 0755 -o ${userConfig.username} -g staff '${screenshotDirectory}'
    '';
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
