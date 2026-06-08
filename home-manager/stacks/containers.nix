# Container and image tooling.
{
  lib,
  pkgs,
  ...
}:
let
  containerContext = pkgs.writeShellApplication {
    name = "container-context";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        jq
      ]
      ++ lib.optionals stdenv.isLinux [
        systemd
      ];
    text = builtins.readFile ../scripts/container-context.sh;
  };
in
{
  home.packages = [
    containerContext
  ]
  ++ (with pkgs; [
    crane # Container registry tool
    docker-client # Docker CLI for context management and Starship prompt state
    lazydocker # Docker TUI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility
  ]);

  systemd.user = lib.mkIf pkgs.stdenv.isLinux {
    sockets.podman = {
      Unit.Description = "Podman API socket";
      Socket = {
        ListenStream = "%t/podman/podman.sock";
        SocketMode = "0600";
        DirectoryMode = "0700";
      };
      Install.WantedBy = [ "sockets.target" ];
    };

    services.podman = {
      Unit = {
        Description = "Podman API service";
        Requires = [ "podman.socket" ];
        After = [ "podman.socket" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      };
    };
  };

  programs.zsh = {
    oh-my-zsh.plugins = [
      "docker-compose"
      "docker"
      "podman"
    ];

    initContent = lib.mkAfter ''
      _container_clear_docker_overrides() {
        unset DOCKER_HOST
        unset CONTAINER_HOST
        unset CONTAINER_CONNECTION
        unset DOCKER_CONTEXT
        unalias docker docker-compose 2>/dev/null || true
      }

      _container_context() {
        _container_clear_docker_overrides
        container-context "$@"
      }

      ctx-colima() {
        _container_context colima "$@"
      }

      ctx-podman() {
        _container_context podman rootless \
          "''${PODMAN_ROOTLESS_CONTEXT:-podman-rootless}" \
          "''${PODMAN_ROOTLESS_MACHINE:-podman-machine-default}"
      }

      ctx-podman-rootful() {
        _container_context podman rootful \
          "''${PODMAN_ROOTFUL_CONTEXT:-podman-rootful}" \
          "''${PODMAN_ROOTFUL_MACHINE:-podman-machine-rootful}"
      }

      # If `docker` resolves to podman, use podman's completion backend.
      if (( $+commands[podman] && $+commands[docker] )) && command docker --version 2>/dev/null | command grep -qi '^podman version'; then
        compdef _podman docker
      fi

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        if (( $+commands[podman] )); then
          autoload -Uz _podman
          compdef _podman podman
        fi
      ''}
    '';
  };
}
