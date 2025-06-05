{ pkgs, ... }:
{
  nix.package = pkgs.nix;
  imports = [
    ../programs/fzf.nix
    ../programs/lsd.nix
    ../programs/starship.nix
    ../programs/tmux.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix
  ];
  # programs.zsh.initExtraFirst = ''
  #   . $HOME/.nix-profile/etc/profile.d/nix.sh
  # '';
  home = {
    username = "vscode";
    homeDirectory = "/home/vscode";
    stateVersion = "25.11";
    packages = with pkgs; [ cowsay ];
  };
}
