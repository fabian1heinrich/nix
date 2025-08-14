{ pkgs, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/default.nix
    ../../home-manager/programs/broot.nix
    ../../home-manager/programs/fzf.nix
    ../../home-manager/programs/git.nix
    ../../home-manager/programs/lsd.nix
    ../../home-manager/programs/starship.nix
    ../../home-manager/programs/tmux.nix
    ../../home-manager/programs/yazi.nix
    ../../home-manager/programs/zoxide.nix
    ../../home-manager/programs/zsh.nix
    # TODO: ghostty
    # ../../home-manager/programs/zsh.nix/ghostty.nix
  ];
  home = {
    username = "fabian";
    homeDirectory = "/Users/fabian";
    stateVersion = "25.05";
    packages = with pkgs; [
      alacritty
      bitwarden-desktop
      colima
      discord
      docker-buildx
      docker-client
      docker-compose
      gh
      openvpn
      slack
      utm
      vscode
      zoom-us
      zotero
    ];
  };
}
