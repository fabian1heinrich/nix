# Common package set shared by non-minimal profiles
{ pkgs, ... }:
let
  # devcontainer's yarn offline build tries to auto-install node-gyp unless it is already in PATH.
  devcontainerWithNodeGyp = pkgs.devcontainer.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.nodePackages."node-gyp" ];
    npm_config_node_gyp = "${pkgs.nodePackages."node-gyp"}/bin/node-gyp";
  });
in
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
    devcontainerWithNodeGyp # Dev container CLI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility

    # Kubernetes tools
    kubectl # Kubernetes CLI
    kubectl-view-secret # View K8s secrets
    kubectx # Switch contexts/namespaces
    kubernetes-helm # Helm package manager
    kubie # K8s context manager
    kustomize # K8s configuration
    kyverno # K8s policy engine
    fluxcd # GitOps toolkit
    stern # Multi-pod log tailing
    zarf # Air-gap K8s deployments

    # Nix tooling
    nixd # Nix language server
    nixfmt # Nix formatter

    # Fonts
    nerd-fonts.meslo-lg
  ];
  # Font configuration (Linux only - macOS uses its own font system)
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "MesloLGS Nerd Font Mono" ];
    };
  };
}
