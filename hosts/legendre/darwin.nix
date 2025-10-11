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

  users.users.fabian = {
    home = "/Users/fabian";
    shell = pkgs.zsh;
  };
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
          "/Applications/Zen.app"
          "${pkgs.vscode}/Applications/Visual Studio Code.app/"
          "/System/Applications/Calendar.app/"
          "/Applications/Signal.app/"
          "${pkgs.slack}/Applications/Slack.app/"
          "${pkgs.discord}/Applications/Discord.app/"
          "/System/Applications/System Settings.app/"
        ];
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "Nlsv";
        NewWindowTarget = "Other";
        NewWindowTargetPath = "file:///Users/fabian/";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };
      menuExtraClock = {
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = false;
        ShowAMPM = true;
      };
      trackpad = {
        # TODO
      };
    };
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    extraConfig = "";
    brewPrefix = "/opt/homebrew/bin";
    brews = [
      "codex"
      "cowsay"
    ];
    # TODO: enable when 25.11 is out
    # greedyCasks = "true";
    casks = [
      "aldente"
      "ccleaner"
      "ghostty"
      "gifox"
      "jordanbaird-ice"
      "languagetool-desktop"
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
      "yubico-authenticator"
      "zen"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };
}
