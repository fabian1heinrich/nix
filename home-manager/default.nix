{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      bat
      crane
      fd
      fzf
      git
      jetbrains-mono
      k9s
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
      nixd
      nixfmt-rfc-style
      ripgrep
      skopeo
      stern
      television
      tldr
      tmux
      tree
      wget
      zarf
      zoxide
    ];
  };
}
