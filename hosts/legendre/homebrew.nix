{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    extraConfig = "";
    prefix = "/opt/homebrew";
    brews = [
      "cowsay"
    ];
    greedyCasks = true;
    casks = [
      "aldente"
      "betterdisplay"
      "bettershot"
      "ccleaner"
      "claude"
      "ghostty"
      "gifox"
      "glide"
      "languagetool-desktop"
      "logi-options+"
      "maccy"
      "nightfall"
      "raycast"
      "selfcontrol"
      "shottr"
      "signal"
      "stats"
      "thaw"
      "visual-studio-code"
      "yubico-authenticator"
      "zen"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };
}
