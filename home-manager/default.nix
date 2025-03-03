{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
  home = {
    packages = with pkgs; [
      bat
      fd
      fzf
      git
      k9s
      kind
      kind
      kubecolor
      kubectl
      kubectx
      kubernetes-helm
      kubeswitch
      kubie
      kustomize
      lazydocker
      lazygit
      meslo-lgs-nf
      nerd-fonts.jetbrains-mono
      nixfmt-rfc-style
      ripgrep
      stern
      television
      tldr
      tree
      wget
      zarf
      zoxide
    ];
  };
}
