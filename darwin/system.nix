{ pkgs, ... }:
{

  system = {
    # keyboard.enableKeyMapping = true;
    # keyboard.remapCapsLockToEscape = true;
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        _HIHideMenuBar = false;
      };
      dock = {
        autohide = true;
        orientation = "right";
        show-recents = false;
        persistent-apps = [
          "/Applications/Ghostty.app/"
          "${pkgs.arc-browser}/Applications/Arc.app/"
          "${pkgs.vscode}/Applications/Visual Studio Code.app/"
          "/System/Applications/Calendar.app/"
          "${pkgs.signal-desktop}/Applications/Signal.app/"
          "${pkgs.slack}/Applications/Slack.app/"
        ];
      };
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
      };
    };
  };
  services.nix-daemon.enable = true;
  system.stateVersion = 6;
}
