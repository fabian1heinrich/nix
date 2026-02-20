{ pkgs, userConfig, ... }:
{
  imports = [
    ../../profiles/linux-desktop.nix
    ../../home-manager/programs/broot.nix
  ];

  # Needed due to installation w/ determinate installer
  nix.settings.extra-nix-path = "nixpkgs=flake:nixpkgs";

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
      qemu
      virt-manager

      # Infrastructure as Code (IaC)
      opentofu
    ];
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
}
