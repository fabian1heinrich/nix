{
  pkgs,
  qemuPkgs ? pkgs,
  userConfig,
  ...
}:
{
  imports = [
    ../../profiles/desktop-linux.nix
    ./ubuntu.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    packages = with pkgs; [
      # AI tools
      codex

      # Container & virtualization
      ctop
      (lib.hiPrio (
        writeShellScriptBin "kind" ''
          exec systemd-run --scope --user -p "Delegate=yes" ${kind}/bin/kind "$@"
        ''
      ))
      kind
      qemuPkgs.qemu
      virt-manager
      virtiofsd

      # Infrastructure as Code (IaC)
      opentofu
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
    };
  };

}
