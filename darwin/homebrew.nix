# Not using anymore
{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      upgrade = true;
    };
    brewPrefix = "/opt/homebrew/bin";
    # global = {
    #   brewfile = true;
    # };
    casks = [
      "ccleaner"
      "docker"
      "gifox"
      "jordanbaird-ice"
      "selfcontrol"
      "shottr"
      # "tresorit"
      "zoom"
      "nightfall"
      "ghostty"
    ];
  };
}
