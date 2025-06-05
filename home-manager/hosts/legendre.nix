{ pkgs, ... }:
{
  imports = [
    ../programs/fzf.nix
    ../programs/git.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/tmux.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
    # TODO: ghostty
    # ../programs/ghostty.nix
  ];
  home = {
    username = "fabian";
    homeDirectory = "/Users/fabian";
    stateVersion = "25.11";
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
