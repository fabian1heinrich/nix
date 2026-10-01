# Kubernetes tooling and related program configuration.
{
  pkgs,
  sofka,
  ...
}:
{
  imports = [
    ../programs/hauler.nix
    ../programs/k9s.nix
    ../programs/kubecolor.nix
    ../programs/kubeswitch.nix
  ];

  home.packages = with pkgs; [
    cloud-provider-kind # LoadBalancer implementation for kind clusters
    fluxcd # GitOps toolkit
    fluxcd-operator # GitOps toolkit
    kind # Local Kubernetes clusters using container nodes
    kubectl # Kubernetes CLI
    kubectl-view-secret # View K8s secrets
    kubectx # Switch contexts/namespaces
    kubernetes-helm # Helm package manager
    kubie # K8s context manager
    kustomize # K8s configuration
    kyverno # K8s policy engine
    sofka.packages.${pkgs.stdenv.hostPlatform.system}.default # Kubernetes TUI
    stern # Multi-pod log tailing
    talhelper # Talos OS helper
    talosctl # Talos OS management
    zarf # Air-gap K8s deployments
  ];

  programs.zsh = {
    oh-my-zsh.plugins = [
      "kubectl"
    ];

    shellAliases = {
      k = "kubectl";
      kns = "kubens";
      kctx = "kubectx";
    };
  };
}
