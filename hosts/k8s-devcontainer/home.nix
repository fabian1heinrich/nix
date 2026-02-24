{ pkgs, userConfig, ... }:
{
  imports = [
    ../../home-manager/home.nix
    ../../home-manager/programs/fzf.nix
    ../../home-manager/programs/gh.nix
    ../../home-manager/programs/lsd.nix
    ../../home-manager/programs/starship.nix
    ../../home-manager/programs/zoxide.nix
    ../../home-manager/programs/zsh.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # File & text utilities
      bat # Better cat with syntax highlighting
      fd # Better find
      ripgrep # Better grep
      jq # JSON processor
      yq # YAML processor
      tree # Directory tree viewer
      glow # Markdown renderer
      mawk # Fast awk implementation

      # Disk & system utilities

      wget # File downloader
      tldr # Simplified man pages
      television # TUI file browser

      # Git & development
      lazygit # Git TUI
      httpie # HTTP client

      # Container & image tools
      crane # Container registry tool
      devcontainer # Dev container CLI
      oras # OCI registry client
      regctl # Registry client
      skopeo # Container image utility

      # Kubernetes tools
      k9s # Kubernetes TUI
      kubecolor # Colorized kubectl
      kubectl # Kubernetes CLI
      kubectl-view-secret # View K8s secrets
      kubectx # Switch contexts/namespaces
      kubernetes-helm # Helm package manager
      kubeswitch # Context switcher
      kubie # K8s context manager
      kustomize # K8s configuration
      kyverno # K8s policy engine
      fluxcd # GitOps toolkit
      stern # Multi-pod log tailing
      zarf # Air-gap K8s deploymentss
    ];
  };
}
