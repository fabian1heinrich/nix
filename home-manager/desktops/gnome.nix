{
  lib,
  pkgs,
  ...
}:
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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.gnome.Evince.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  dconf.settings = {
    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Shift>Print" ];
      screenshot-window = [ "<Alt>Print" ];
      show-screenshot-ui = [ "Print" ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
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
        "date_modified"
      ];
      default-zoom-level = "small";
      use-tree-view = false;
    };

    "org/gnome/nautilus/icon-view".default-zoom-level = "small";

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

    "org/gnome/system/locale".region = "en_GB.UTF-8";

    "org/gnome/GWeather4" = {
      temperature-unit = "centigrade";
      distance-unit = "km";
      speed-unit = "kph";
    };

    "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 900;

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

    "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";

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

    "org/gnome/desktop/peripherals/mouse".natural-scroll = true;

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-schedule-automatic = true;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      calculator = [ "<Super>c" ];
      control-center = [ "<Super>i" ];
      screensaver = [ "<Super>l" ];
    };
  };
}
