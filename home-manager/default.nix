{ pkgs, ... }: {
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
  home = {
    packages = with pkgs; [
      bat
      fd
      fluxcd
      fzf
      git
      k9s
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
      nixfmt
      nixd
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
