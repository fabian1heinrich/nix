{ pkgs, userConfig, ... }:
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
  users.users.${userConfig.username} = {
    home = userConfig.homeDirectory;
    shell = pkgs.zsh;
  };
  system = {
    primaryUser = userConfig.username;
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
        launchanim = false;
        tilesize = 64;
        minimize-to-application = true;
        mineffect = "scale";
        persistent-apps = [
          "/Applications/Ghostty.app/"
          "/Applications/Zen.app"
          "/Applications/Visual\ Studio\ Code.app/"
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
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        NewWindowTargetPath = "file://$\{HOME\}";
        FXEnableExtensionChangeWarning = false;
      };
      menuExtraClock = {
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = false;
        ShowAMPM = true;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleCalendar = "gregorian";
          AppleLocale = "en_US";
          AppleFirstWeekday = {
            gregorian = 2;
          };
          AppleMeasurementUnits = "Centimeters";
          AppleICUDateFormatStrings = {
            "1" = "MM/dd/yyyy";
          };
          AppleICUNumberFormatStrings = {
            "1" = "#,##0.###";
          };
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.loginwindow" = {
          GuestEnabled = false;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };
        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 0;
              "KeyboardLayout Name" = "U.S.";
            }
          ];
          AppleSelectedInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 0;
              "KeyboardLayout Name" = "U.S.";
            }
          ];
        };
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
      "cowsay"
    ];
    greedyCasks = true;
    casks = [
      "visual-studio-code"
      "aldente"
      "ccleaner"
      "claude"
      "ghostty"
      "gifox"
      "jordanbaird-ice"
      "languagetool-desktop"
      "maccy"
      "betterdisplay"
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
      "logi-options+"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };
}
