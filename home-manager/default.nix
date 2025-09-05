{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      bat
      crane
      dua
      dust
      fd
      glow
      httpie
      jetbrains-mono
      jq
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
      procs
      ripgrep
      skopeo
      stern
      television
      tldr
      tree
      wget
      zarf
    ];
  };
}
