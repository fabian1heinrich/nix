{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      extraFlags = [ "--force-cleanup" ];
      upgrade = false;
    };
    extraConfig = "";
    prefix = "/opt/homebrew";
    brews = [
      "cowsay"
      "lima-additional-guestagents"
      "mas"
      "mise"
      "mole"
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
      "snapzy"
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
