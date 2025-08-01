{ pkgs, ... }:
{
  nix = {
    enable = true;
    settings = {
      "experimental-features" = [
        "nix-command"
        "flakes"
      ];
    };
  };

  programs.zsh.enable = true;
  users.users.fabian.home = "/Users/fabian";
  system = {
    primaryUser = "fabian";
    stateVersion = 6;
    defaults = {
      NSGlobalDomain = {
        _HIHideMenuBar = false;
        AppleInterfaceStyle = "Dark";
        AppleMetricUnits = 1;
        AppleShowAllExtensions = true;
        AppleTemperatureUnit = "Celsius";
      };
      dock = {
        autohide = true;
        orientation = "right";
        show-recents = false;
        persistent-apps = [
          "/Applications/Ghostty.app/"
          "${pkgs.arc-browser}/Applications/Arc.app/"
          "${pkgs.vscode}/Applications/Visual Studio Code.app/"
          "/System/Applications/Calendar.app/"
          "/Applications/Signal.app/"
          "${pkgs.slack}/Applications/Slack.app/"
          "/System/Applications/System Settings.app/"
        ];
      };
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
      };

    };
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      upgrade = true;
    };
    brewPrefix = "/opt/homebrew/bin";
    casks = [
      "aldente"
      "ccleaner"
      "ghostty"
      "gifox"
      "jordanbaird-ice"
      "languagetool"
      "maccy"
      "monitorcontrol"
      "mos"
      "nightfall"
      "proton-drive"
      "raycast"
      "selfcontrol"
      "shottr"
      "signal"
      "stats"
      "yubico-yubikey-manager"

    ];
  };
}
