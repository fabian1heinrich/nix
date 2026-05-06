# Kubernetes-focused devcontainer profile
{ ... }:
{
  imports = [
    ./base.nix
    ../home-manager/stacks/development.nix
    ../home-manager/stacks/kubernetes.nix
  ];
}
