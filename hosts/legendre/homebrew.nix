{
  config,
  userConfig,
  homebrew-core,
  homebrew-cask,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    user = userConfig.username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };
    extraConfig = "";
    prefix = "/opt/homebrew";
    brews = [
      "colima"
      "cowsay"
      "lima-additional-guestagents"
      "mas"
      "mole"
      "podman"
      "qemu"
      "socket_vmnet"
    ];
    greedyCasks = true;
    casks = [
      "aldente"
      "betterdisplay"
      "bettershot"
      "chatgpt"
      "ghostty"
      "gpg-suite"
      "herdr-app"
      "languagetool-desktop"
      "logi-options+"
      "maccy"
      "nightfall"
      "openvpn-connect"
      "raycast"
      "selfcontrol"
      "signal"
      "slack"
      "stats"
      "thaw"
      "visual-studio-code"
      "yubico-authenticator"
      "zen"
      "zoom"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };

  # Clean daily even when no packages are installed or upgraded.
  launchd.daemons.homebrew-cleanup = {
    command = "${config.homebrew.prefix}/bin/brew cleanup --prune=all";
    environment.HOME = userConfig.homeDirectory;
    serviceConfig = {
      UserName = config.homebrew.user;
      StartCalendarInterval = {
        Hour = 3;
        Minute = 45;
      };
    };
  };
}
