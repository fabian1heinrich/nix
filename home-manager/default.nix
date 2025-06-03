{pkgs, ...}: {
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
  home = {
    packages = with pkgs; [
      alejandra
      bat
      crane
      devcontainer
      fd
      fzf
      git
      k3d
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
      ripgrep
      skopeo
      stern
      talosctl
      television
      tldr
      tmux
      tree
      unixtools.ping
      wget
      zarf
      zoxide
      nixd
    ];
  };
}
