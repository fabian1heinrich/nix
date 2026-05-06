{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    extraConfig = "";
    prefix = "/opt/homebrew";
    brews = [
      "cowsay"
      "mas"
      "podman"
      "podman-compose"
      "qemu"
    ];
    greedyCasks = false;
    casks = [
      "aldente"
      "betterdisplay"
      "bettershot"
      "bitwarden"
      "ccleaner"
      "chatgpt"
      "claude"
      "codex"
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
