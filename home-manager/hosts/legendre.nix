{ pkgs, ... }:
{
  imports = [
    ../programs/fzf.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
    # ../programs/ghostty.nix
  ];
  programs.zsh.enable = true;
  home = {
    username = "fabian";
    homeDirectory = "/Users/fabian";
    stateVersion = "25.05";
    packages = with pkgs; [
      alacritty
      aldente
      arc-browser
      discord
      gh
      languagetool
      maccy
      monitorcontrol
      mos
      raycast
      signal-desktop
      slack
      stats
      utm
      vscodium
      vscode
      # ghostty
      zotero
    ];
  };
}
