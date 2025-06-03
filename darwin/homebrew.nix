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
      "docker"
      "gifox"
      "jordanbaird-ice"
      "selfcontrol"
      "shottr"
      # "tresorit"
      "zoom"
      "nightfall"
      "ghostty"
      "yubico-yubikey-manager"
      "bitwarden"
      "openvpn-connect"
    ];
  };
}
