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
  home = {
    username = "ubuntu-dev";
    homeDirectory = "/home/ubuntu-dev";
    stateVersion = "25.05";
    packages = with pkgs; [
      colima
      docker-buildx
      docker-client
      docker-compose
      virt-manager
      vscode
      ungoogled-chromium
    ];
  };
}
