# Container and image tooling.
{
  lib,
  pkgs,
  ...
}:
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
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        if (( $+commands[podman] )); then
          autoload -Uz _podman
          compdef _podman podman
        fi
      ''}
    '';
  };
}
