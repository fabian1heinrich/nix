{
  config,
  lib,
  pkgs,
  ...
}:
let
  zshShell = "${config.home.profileDirectory}/bin/zsh";
in
{
  gtk = {
    enable = true;
    theme.name = "Yaru";
    gtk4.theme = config.gtk.theme;
    cursorTheme = {
      name = "Yaru";
      size = 24;
    };
    iconTheme.name = "Yaru";
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };

  # GNOME Shell already starts ibus-daemon on this Ubuntu session. The
  # distro-provided user unit races it, fails, and leaves systemd degraded.
  xdg.configFile."systemd/user/org.freedesktop.IBus.session.GNOME.service" = {
    source = config.lib.file.mkOutOfStoreSymlink "/dev/null";
    force = true;
  };

  home.activation.resetFailedIbus = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
    $DRY_RUN_CMD env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
      PATH="${pkgs.systemd}/bin:$PATH" \
      systemctl --user reset-failed org.freedesktop.IBus.session.GNOME.service 2>/dev/null || true
  '';

  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "RIGHT";
      extend-height = false;
      dock-fixed = false;
      autohide = true;
      intellihide = true;
      show-mounts = false;
      show-trash = false;
      show-show-apps-button = false;
    };

    "org/gnome/shell".favorite-apps = [
      "org.gnome.Nautilus.desktop"
      "org.gnome.Terminal.desktop"
      "google-chrome.desktop"
      "code.desktop"
      "org.gnome.Settings.desktop"
    ];

    "org/gnome/desktop/interface" = {
      icon-theme = "Yaru";
      cursor-theme = "Yaru";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 1800;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "gnome-terminal";
      name = "Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>b";
      command = "google-chrome";
      name = "Browser";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Super>e";
      command = "nautilus";
      name = "Files";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      use-custom-command = true;
      custom-command = zshShell;
      login-shell = false;
    };
  };
}
