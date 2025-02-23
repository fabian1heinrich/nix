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
      kustomize
      lazydocker
      lazygit
      meslo-lgs-nf
      nerd-fonts.jetbrains-mono
      nixfmt-rfc-style
      ripgrep
      television
      tldr
      tree
      wget
      zarf
      zoxide
      kubie
      kubeswitch
    ];
  };
}
