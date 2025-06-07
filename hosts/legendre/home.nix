{ pkgs, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/default.nix
    ../../home-manager/programs/fzf.nix
    ../../home-manager/programs/git.nix
    ../../home-manager/programs/lsd.nix
    ../../home-manager/programs/starship.nix
    ../../home-manager/programs/tmux.nix
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
      arc-browser
      colima
      discord
      gh
      openvpn
      slack
      utm
      vscode
      zotero
      bitwarden-desktop
      openvpn
      zoom-us
    ];
  };
}
