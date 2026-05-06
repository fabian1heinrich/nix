# Container and image tooling.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    crane # Container registry tool
    lazydocker # Docker TUI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility
  ];
}
