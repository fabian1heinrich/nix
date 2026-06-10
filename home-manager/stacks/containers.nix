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
        docker-client
        jq
      ]
      ++ lib.optionals stdenv.isLinux [
        systemd
      ];
    text = builtins.readFile ../scripts/container-context.sh;
  };
  containerPromptContext = pkgs.writeShellApplication {
    name = "container-prompt-context";
    runtimeInputs = with pkgs; [
      coreutils
      docker-client
      jq
    ];
    text = builtins.readFile ../scripts/container-prompt-context.sh;
  };
in
{
  home.packages = [
    containerContext
    containerPromptContext
  ]
  ++ (with pkgs; [
    crane # Container registry tool
    docker-client # Docker CLI for context management and Starship prompt state
    docker-compose # Docker Compose CLI and plugin
    lazydocker # Docker TUI
    oras # OCI registry client
    regctl # Registry client
    skopeo # Container image utility
  ]);

  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";

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
      _container_clear_connection_overrides() {
        unset DOCKER_HOST
        unset CONTAINER_HOST
        unset CONTAINER_CONNECTION
        unalias docker docker-compose 2>/dev/null || true
      }

      _container_use_context() {
        local context

        _container_clear_connection_overrides
        context="$(container-context "$@")" || return
        export DOCKER_CONTEXT="$context"
      }

      ctx-colima() {
        _container_use_context colima "$@"
      }

      ctx-podman() {
        _container_use_context podman rootless \
          "''${PODMAN_ROOTLESS_CONTEXT:-podman}" \
          "''${PODMAN_ROOTLESS_MACHINE:-podman-machine-default}"
      }

      ctx-podman-rootful() {
        _container_use_context podman rootful \
          "''${PODMAN_ROOTFUL_CONTEXT:-podman-root}" \
          "''${PODMAN_ROOTFUL_MACHINE:-podman-machine-rootful}"
      }

      ctx-default() {
        _container_clear_connection_overrides
        export DOCKER_CONTEXT=default
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
