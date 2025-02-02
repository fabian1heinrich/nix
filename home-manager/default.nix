{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  home = {
    packages = with pkgs; [
      bat
      fd
      fzf
      git
      kubernetes-helm
      k9s
      kind
      kubectl
      kubectx
      kustomize
      lazydocker
      lazygit
      meslo-lgs-nf
      nixfmt-rfc-style
      ripgrep
      television
      tldr
      tree
      wget
      zarf
      zoxide
    ];
  };
}
