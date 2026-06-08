{
  config,
  pkgs,
  lib,
  ...
}:
let
  zshShell = "${config.home.profileDirectory}/bin/zsh";
in
{
  home.packages = with pkgs; [
    dconf-editor
    gnome-tweaks
    pavucontrol
    pinentry-gnome3
    seahorse
    wl-clipboard
    xclip
  ];

  # GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "Yaru";
      package = pkgs.yaru-theme;
    };
    gtk4.theme = config.gtk.theme;
    cursorTheme = {
      name = "Yaru";
      package = pkgs.yaru-theme;
      size = 24;
    };
    iconTheme = {
      name = "Yaru";
      package = pkgs.yaru-theme;
    };
  };

  home.pointerCursor = {
    name = "Yaru";
    package = pkgs.yaru-theme;
    x11.enable = true;
    gtk.enable = true;
    size = 24;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.gnome.Evince.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

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

    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Terminal.desktop"
        "google-chrome.desktop"
        "code.desktop"
        "org.gnome.Settings.desktop"
      ];
    };

    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Shift>Print" ];
      screenshot-window = [ "<Alt>Print" ];
      show-screenshot-ui = [ "Print" ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Yaru";
      cursor-theme = "Yaru";
      clock-format = "12h";
      clock-show-date = true;
      clock-show-weekday = true;
      clock-show-seconds = false;
      enable-hot-corners = false;
      show-battery-percentage = true;
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = true;
      show-size-column = true;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      window-size = lib.hm.gvariant.mkTuple [
        1200
        800
      ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-filter-time-type = "last_modified";
      show-delete-permanently = true;
    };

    "org/gnome/nautilus/list-view" = {
      default-visible-columns = [
        "name"
        "size"
        # "type"
        # "owner"
        # "permissions"
        "date_modified"
      ];
      default-zoom-level = "small";
      use-tree-view = false;
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "us"
        ])
      ];
      mru-sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "us"
        ])
      ];
      xkb-options = [ ];
    };

    "org/gnome/system/locale" = {
      region = "en_GB.UTF-8";
    };

    "org/gnome/GWeather4" = {
      temperature-unit = "centigrade";
      distance-unit = "km";
      speed-unit = "kph";
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 900;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 1800;
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = lib.hm.gvariant.mkUint32 60;
    };

    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      maximize = [ "<Super>Up" ];
      switch-to-workspace-left = [
        "<Super>Page_Up"
        "<Super><Alt>Left"
      ];
      switch-to-workspace-right = [
        "<Super>Page_Down"
        "<Super><Alt>Right"
      ];
      toggle-fullscreen = [ "F11" ];
      unmaximize = [ "<Super>Down" ];
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      disable-while-typing = true;
      click-method = "fingers";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = true;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      calculator = [ "<Super>c" ];
      control-center = [ "<Super>i" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
      screensaver = [ "<Super>l" ];
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
