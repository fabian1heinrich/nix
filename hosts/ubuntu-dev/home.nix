{ pkgs, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/default.nix
    ../../home-manager/programs/broot.nix
    ../../home-manager/programs/fzf.nix
    ../../home-manager/programs/ghostty.nix
    ../../home-manager/programs/git.nix
    ../../home-manager/programs/lsd.nix
    ../../home-manager/programs/mcfly.nix
    ../../home-manager/programs/navi.nix
    ../../home-manager/programs/starship.nix
    ../../home-manager/programs/zoxide.nix
    ../../home-manager/programs/zsh.nix
  ];

  # needed due to installation w/ determinate installer
  nix.settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  home = {
    username = "ubuntu-dev";
    homeDirectory = "/home/ubuntu-dev";
    stateVersion = "25.05";
    packages = with pkgs; [
      colima
      ctop
      docker-buildx
      docker-client
      docker-compose
      gh
      kind
      ungoogled-chromium
      virt-manager
      vscodium
    ];
  };

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
