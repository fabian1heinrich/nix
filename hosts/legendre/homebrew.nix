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
      "lima-additional-guestagents"
      "mas"
      "mole"
      "podman-compose"
      "podman"
      "qemu"
      "socket_vmnet"
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
      "zed"
      "zen"
      "zoom"
    ];
    masApps = {
      "prime-instant-video" = 545519333; # Amazon Prime Video
    };
  };
}
