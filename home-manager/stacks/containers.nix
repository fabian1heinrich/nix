# Container and image tooling.
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    crane # Container registry tool
    lazydocker # Docker TUI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility
  ];

  programs.zsh = {
    oh-my-zsh.plugins = [
      "docker-compose"
      "docker"
      "podman"
    ];

    shellAliases = {
      docker = lib.mkDefault "podman";
      "docker-compose" = lib.mkDefault "podman-compose";
    };

    initContent = lib.mkAfter ''
      # If `docker` resolves to podman, use podman's completion backend.
      if (( $+commands[podman] && $+commands[docker] )) && command docker --version 2>/dev/null | command grep -qi '^podman version'; then
        compdef _podman docker
      fi

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        if (( $+commands[podman] )); then
          autoload -Uz _podman
          compdef _podman podman docker
        fi
      ''}
    '';
  };
}
