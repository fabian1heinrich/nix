{
  config,
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
}
