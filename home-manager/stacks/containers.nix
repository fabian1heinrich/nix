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
      # Prefer Podman's Docker-compatible socket when it is available.
      # macOS uses the Podman machine API socket; Linux rootless Podman uses XDG_RUNTIME_DIR.
      if [[ -z "''${DOCKER_HOST:-}" ]]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
          _podman_machine="''${PODMAN_MACHINE:-podman-machine-default}"
          _podman_socket="''${HOME}/.tmp/podman/''${_podman_machine}-api.sock"

          if [[ -S "$_podman_socket" ]]; then
            export PODMAN_MACHINE="$_podman_machine"
            export DOCKER_HOST="unix://$_podman_socket"
          fi

          unset _podman_machine _podman_socket
        elif [[ -n "''${XDG_RUNTIME_DIR:-}" && -S "''${XDG_RUNTIME_DIR}/podman/podman.sock" ]]; then
          export DOCKER_HOST="unix://''${XDG_RUNTIME_DIR}/podman/podman.sock"
        elif [[ -S "/run/user/$(id -u)/podman/podman.sock" ]]; then
          export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
        fi
      fi

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
