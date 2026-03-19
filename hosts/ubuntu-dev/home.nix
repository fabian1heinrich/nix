{
  config,
  pkgs,
  qemuPkgs ? pkgs,
  userConfig,
  lib,
  ...
}:
let
  zshShell = "${config.home.profileDirectory}/bin/zsh";
in
{
  imports = [
    ../../profiles/desktop-linux.nix
  ];

  # Needed due to installation w/ determinate installer
  nix = {
    package = pkgs.nixVersions.latest;
    settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  };

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # AI tools
      codex

      # Container & virtualization
      colima
      ctop
      docker-buildx
      docker-client
      docker-compose
      kind
      qemuPkgs.qemu
      virt-manager

      # Infrastructure as Code (IaC)
      opentofu
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
    };
  };

  # GTK theming
  gtk = {
    enable = true;
    theme = {
      name = "Yaru";
      package = pkgs.yaru-theme;
    };
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

  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "RIGHT";
      extend-height = false;
      dock-fixed = false;
      autohide = true;
      intellihide = true;
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

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      use-custom-command = true;
      custom-command = zshShell;
      login-shell = false;
    };
  };
}
