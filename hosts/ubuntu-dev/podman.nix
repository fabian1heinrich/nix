{
  pkgs,
  ...
}:
let
  dataMount = "/media/data";
  rootlessStorage = "${dataMount}/podman/rootless";
in
{
  home.packages = with pkgs; [
    gvproxy
    podman
  ];

  systemd.user = {
    sockets.podman = {
      Unit = {
        Description = "Podman API socket";
        ConditionPathIsMountPoint = dataMount;
      };
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
        ConditionPathIsMountPoint = dataMount;
      };
      Service = {
        Type = "exec";
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      };
    };
  };

  xdg.configFile."containers/containers.conf".text = ''
    [engine]
    compose_providers = [
      "${pkgs.docker-compose}/bin/docker-compose",
    ]
    helper_binaries_dir = [
      "${pkgs.podman}/libexec/podman",
      "${pkgs.gvproxy}/bin",
    ]
  '';

  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    driver = "overlay"
    graphroot = "${rootlessStorage}"
  '';
}
