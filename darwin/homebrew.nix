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
      "aldente"
      "ccleaner"
      "ghostty"
      "gifox"
      "jordanbaird-ice"
      "languagetool"
      "maccy"
      "monitorcontrol"
      "mos"
      "nightfall"
      "raycast"
      "selfcontrol"
      "shottr"
      "signal"
      "stats"
      "yubico-yubikey-manager"
      # "tresorit"
    ];
  };
}
