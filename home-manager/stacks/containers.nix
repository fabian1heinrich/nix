# Portable container and image tooling.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    crane # Container registry tool
    docker-client # Docker-compatible CLI for project-local container endpoints
    docker-compose # Docker Compose CLI and plugin
    lazydocker # Docker TUI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility
  ];

  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";

  programs.zsh.oh-my-zsh.plugins = [
    "docker-compose"
    "docker"
    "podman"
  ];
}
