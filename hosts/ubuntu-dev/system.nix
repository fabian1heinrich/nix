{ pkgs, ... }:
let
  podmanRootful = pkgs.writeShellApplication {
    name = "podman-rootful";
    text = ''
      exec /usr/bin/sudo \
        "${pkgs.coreutils}/bin/env" \
        -u CONTAINER_CONNECTION \
        -u CONTAINER_HOST \
        -u DOCKER_CONTEXT \
        -u DOCKER_HOST \
        -u XDG_CONFIG_HOME \
        -u XDG_RUNTIME_DIR \
        -- \
        "HOME=/root" \
        "${pkgs.podman}/bin/podman" "$@"
    '';
  };
in
{
  nixpkgs.hostPlatform = "x86_64-linux";

  environment = {
    systemPackages = with pkgs; [
      docker-compose
      podman
      podmanRootful
    ];

    etc."containers/containers.conf".text = ''
      [engine]
      compose_providers = [
        "${pkgs.docker-compose}/bin/docker-compose",
      ]
      compose_warning_logs = false
      helper_binaries_dir = [
        "${pkgs.podman}/libexec/podman",
      ]
    '';
  };

  systemd = {
    sockets.podman = {
      description = "Podman API socket";
      documentation = [ "man:podman-system-service(1)" ];
      wantedBy = [ "system-manager.target" ];
      socketConfig = {
        ListenStream = "/run/podman/podman.sock";
        SocketMode = "0660";
      };
    };

    services.podman = {
      description = "Podman API service";
      documentation = [ "man:podman-system-service(1)" ];
      requires = [ "podman.socket" ];
      after = [ "podman.socket" ];
      serviceConfig = {
        Delegate = true;
        Type = "exec";
        KillMode = "process";
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      };
    };
  };

  # Make rootful Quadlet files in /etc/containers/systemd discoverable by the
  # host's systemd without installing Podman through apt.
  systemd.generators.podman-system-generator = "${pkgs.podman}/lib/systemd/system-generators/podman-system-generator";
}
