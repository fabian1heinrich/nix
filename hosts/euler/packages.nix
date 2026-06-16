{
  eulerInstallerIso,
  pkgs,
}:
let
  installerVmScript = builtins.path {
    path = ./installer-vm.sh;
    name = "euler-installer-vm.sh";
  };

  eulerInstallerVm = pkgs.writeShellApplication {
    name = "euler-installer-vm";
    runtimeInputs = with pkgs; [
      coreutils
      qemu_kvm
    ];
    text = ''
      export EULER_VM_ISO="${eulerInstallerIso}/iso/euler-installer.iso"
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
    euler-installer-iso = eulerInstallerIso;
    euler-installer-vm = eulerInstallerVm;
  };

  apps = {
    euler-installer-vm = {
      type = "app";
      program = "${eulerInstallerVm}/bin/euler-installer-vm";
    };
  };
}
