# Minimal package set shared by all profiles.
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # File & text utilities
    bat # Better cat with syntax highlighting
    fd # Better find
    ripgrep # Better grep
    jq # JSON processor
    yq # YAML processor
    tree # Directory tree viewer
    glow # Markdown renderer
    mawk # Fast awk implementation

    # Disk & system utilities
    btop # System monitor
    dua # Disk usage analyzer
    dust # Disk usage (du alternative)
    procs # Better ps
    hyperfine # Command benchmarking
    wget # File downloader
    tldr # Simplified man pages
    television # TUI file browser
    yubikey-manager # YubiKey management CLI

    # Nix tooling
    nixd # Nix language server
    nixfmt # Nix formatter

    # Fonts
    nerd-fonts.meslo-lg
  ];

  fonts.fontconfig = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    defaultFonts = {
      monospace = [ "MesloLGS Nerd Font Mono" ];
    };
  };
}
