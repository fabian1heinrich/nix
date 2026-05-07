# Kubernetes tooling and related program configuration.
{ pkgs, ... }:
{
  imports = [
    ./containers.nix
    ../programs/just.nix
    ../programs/k9s.nix
    ../programs/kubecolor.nix
    ../programs/kubeswitch.nix
  ];

  home.packages = with pkgs; [
    fluxcd # GitOps toolkit
    kubectl # Kubernetes CLI
    kubectl-view-secret # View K8s secrets
    kubectx # Switch contexts/namespaces
    kubernetes-helm # Helm package manager
    kubie # K8s context manager
    kustomize # K8s configuration
    kyverno # K8s policy engine
    stern # Multi-pod log tailing
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
