{ pkgs, ... }: {
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
      # signal-desktop
      slack
      stats
      utm
      vscodium
      vscode
      # ghostty
      zotero
      openvpn
    ];
  };
}
