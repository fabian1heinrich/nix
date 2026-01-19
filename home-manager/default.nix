# Common packages shared across all hosts
{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    btop # System monitor
    dua # Disk usage analyzer
    dust # Disk usage (du alternative)
    procs # Better ps
    hyperfine # Command benchmarking
    wget # File downloader
    tldr # Simplified man pages
    television # TUI file browser

    # Git & development
    lazygit # Git TUI
    lazydocker # Docker TUI
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
    zarf # Air-gap K8s deployments

    # Nix tooling
    nixd # Nix language server
    nixfmt-rfc-style # Nix formatter

    # Fonts
    jetbrains-mono # Programming font
    fira-code # FiraCode font
    fira-code-symbols # FiraCode symbols
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.meslo-lg # Powerline font (includes mono variant)
  ];
  # TODO fix fontconfig settings
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "FiraCode" ];
    };
  };
}
