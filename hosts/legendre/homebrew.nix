{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      extraFlags = [ "--force-cleanup" ];
      upgrade = false;
    };
    extraConfig = "";
    prefix = "/opt/homebrew";
    brews = [
      "colima"
      "cowsay"
      "docker"
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
      "chatgpt"
      "codex"
      "ghostty"
      "gifox"
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
