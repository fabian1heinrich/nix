{
  eulerBaremetalInstallerIso,
  eulerVmInstallerIso,
  pkgs,
}:
let
  installerVmScript = builtins.path {
    path = ./installer-vm.sh;
    name = "euler-installer-vm.sh";
  };

  eulerVmInstallerVm = pkgs.writeShellApplication {
    name = "euler-vm-installer-vm";
    runtimeInputs = with pkgs; [
      coreutils
      qemu_kvm
    ];
    text = ''
      export EULER_VM_OVMF_CODE="${pkgs.OVMF.fd}/FV/OVMF_CODE.fd"
      export EULER_VM_OVMF_VARS_SRC="${pkgs.OVMF.fd}/FV/OVMF_VARS.fd"

      exec ${pkgs.bash}/bin/bash ${installerVmScript} "$@"
    '';
  };
in
{
  shellScripts = [
    installerVmScript
  ];

  packages = {
    euler-baremetal-installer-iso = eulerBaremetalInstallerIso;
    euler-installer-iso = eulerBaremetalInstallerIso;
    euler-vm-installer-iso = eulerVmInstallerIso;
    euler-vm-installer-vm = eulerVmInstallerVm;
  };

  apps = {
    euler-installer-vm = {
      type = "app";
      program = "${eulerVmInstallerVm}/bin/euler-vm-installer-vm";
    };
    euler-vm-installer-vm = {
      type = "app";
      program = "${eulerVmInstallerVm}/bin/euler-vm-installer-vm";
    };
  };
}
