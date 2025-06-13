{ pkgs, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/default.nix
    ../../home-manager/programs/fzf.nix
    ../../home-manager/programs/ghostty.nix
    ../../home-manager/programs/git.nix
    ../../home-manager/programs/lsd.nix
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
      gh
      kind
      virt-manager
    ];
  };
}
