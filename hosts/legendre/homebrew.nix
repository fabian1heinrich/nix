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
      "podman"
      "podman-compose"
      "qemu"
    ];
    greedyCasks = true;
    casks = [
      "aldente"
      "betterdisplay"
      "bettershot"
      "bitwarden"
      "ccleaner"
      "chatgpt"
      "claude"
      "discord"
      "flashspace"
      "ghostty"
      "gifox"
      "glide"
      "languagetool-desktop"
      "logi-options+"
      "maccy"
      "nightfall"
      "raycast"
      "selfcontrol"
      "signal"
      "slack"
      "stats"
      "thaw"
      "utm"
      "visual-studio-code"
      "yubico-authenticator"
      "zen"
      "zoom"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };
}
