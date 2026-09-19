{ userConfig, ... }:
let
  screenshotDirectory = "${userConfig.homeDirectory}/Downloads/screenshots";
in
{
  system.defaults = {
    NSGlobalDomain = {
      _HIHideMenuBar = false;
      AppleKeyboardUIMode = 3;
      AppleInterfaceStyle = "Dark";
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      AppleTemperatureUnit = "Celsius";
      AppleWindowTabbingMode = "manual";
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
    };
    controlcenter.BatteryShowPercentage = true;
    dock = {
      autohide = true;
      mru-spaces = false;
      orientation = "right";
      show-recents = false;
      show-process-indicators = true;
      showhidden = true;
      scroll-to-open = true;
      launchanim = false;
      tilesize = 64;
      minimize-to-application = true;
      mineffect = "scale";
      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/Zen.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Zed.app"
        "/System/Applications/Calendar.app"
        "/Applications/Signal.app"
        "/Applications/Slack.app"
        "/System/Applications/System Settings.app"
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
      _FXEnableColumnAutoSizing = true;
      _FXShowPosixPathInTitle = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
      NewWindowTargetPath = "file://${userConfig.homeDirectory}";
      FXEnableExtensionChangeWarning = false;
    };
    menuExtraClock = {
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
      ShowAMPM = true;
    };
    screencapture = {
      location = screenshotDirectory;
      show-thumbnail = false;
      type = "png";
    };
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };
    loginwindow = {
      DisableConsoleAccess = true;
      GuestEnabled = false;
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
        AppleFirstWeekday.gregorian = 2;
        AppleICUDateFormatStrings."1" = "MM/dd/yyyy";
        AppleICUNumberFormatStrings."1" = "#,##0.###";
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        ScheduleFrequency = 1;
        AutomaticDownload = 1;
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
}
