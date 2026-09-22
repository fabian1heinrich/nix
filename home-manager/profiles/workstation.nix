# Complete interactive workstation environment.
{ ... }:
{
  imports = [
    ./base.nix
    ../programs/vscode
    ../stacks/containers.nix
    ../stacks/development.nix
    ../stacks/kubernetes.nix
    ../stacks/networking.nix
    ../stacks/terminal.nix
  ];
}
