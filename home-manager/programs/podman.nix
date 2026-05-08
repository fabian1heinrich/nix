{ lib, pkgs, ... }:
let
  dockerCompat = pkgs.writeShellScriptBin "docker" ''
    exec podman "$@"
  '';

  dockerComposeCompat = pkgs.writeShellScriptBin "docker-compose" ''
    exec podman-compose "$@"
  '';

  helperBinaries =
    if pkgs.stdenv.isDarwin then
      [
        "/opt/homebrew/bin"
        "/opt/homebrew/opt/podman/libexec"
        "/usr/local/bin"
        "/usr/local/opt/podman/libexec"
      ]
    else
      [
        "${pkgs.podman}/libexec/podman"
        "${pkgs.gvproxy}/bin"
      ];
in
{
  home.packages =
    [
      dockerCompat
      dockerComposeCompat
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      pkgs.podman
      pkgs.podman-compose
      pkgs.gvproxy
    ];

  xdg.configFile."containers/containers.conf".text = ''
    [engine]
    compose_providers = [
      "podman-compose",
    ]
    helper_binaries_dir = [
  ''
  + (lib.concatMapStringsSep "\n" (dir: ''      "${dir}",'') helperBinaries)
  + ''
    ]
  '';
}
