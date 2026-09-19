{ pkgs, userConfig, ... }:
let
  dataMount = "/media/data";
  rootlessStorage = "${dataMount}/podman/rootless";
  rootfulStorage = "${dataMount}/podman/rootful";

  preparePodmanStorage = pkgs.writeShellApplication {
    name = "prepare-podman-storage";
    runtimeInputs = with pkgs; [
      coreutils
      util-linux
    ];
    text = ''
      if ! mountpoint -q ${dataMount}; then
        echo "Podman storage requires ${dataMount} to be mounted; refusing to use the root filesystem." >&2
        exit 1
      fi

      install -d -m 0755 ${dataMount}/podman
      install -d -m 0700 -o ${userConfig.username} -g ${userConfig.primaryGroup} ${rootlessStorage}
      install -d -m 0700 -o root -g root ${rootfulStorage}
    '';
  };

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

    etc."containers/storage.conf".text = ''
      [storage]
      driver = "overlay"
      graphroot = "${rootfulStorage}"
    '';
  };

  systemd = {
    sockets.podman = {
      description = "Podman API socket";
      documentation = [ "man:podman-system-service(1)" ];
      requires = [ "podman-storage.service" ];
      after = [ "podman-storage.service" ];
      wantedBy = [ "system-manager.target" ];
      socketConfig = {
        ListenStream = "/run/podman/podman.sock";
        SocketMode = "0660";
      };
    };

    services.podman = {
      description = "Podman API service";
      documentation = [ "man:podman-system-service(1)" ];
      requires = [
        "podman-storage.service"
        "podman.socket"
      ];
      after = [
        "podman-storage.service"
        "podman.socket"
      ];
      serviceConfig = {
        Delegate = true;
        Type = "exec";
        KillMode = "process";
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      };
    };

    services.podman-storage = {
      description = "Prepare Podman storage on the data mount";
      wantedBy = [ "system-manager.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${preparePodmanStorage}/bin/prepare-podman-storage";
      };
    };
  };

  # Make rootful Quadlet files in /etc/containers/systemd discoverable by the
  # host's systemd without installing Podman through apt.
  systemd.generators.podman-system-generator = "${pkgs.podman}/lib/systemd/system-generators/podman-system-generator";
}
