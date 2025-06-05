{ pkgs, ... }:
{
  # fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
  nix = {
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  home = {
    packages = with pkgs; [
      alejandra
      bat
      crane
      devcontainer
      fd
      fluxcd
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
      jetbrains-mono
      nixfmt-rfc-style
      nixd
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
      docker-buildx
      docker-client
      docker-compose
    ];
  };

}
