{
  eulerSystem,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  image.fileName = "euler-installer.iso";

  isoImage = {
    storeContents = [
      eulerSystem
    ];
  };

  boot.zfs.forceImportRoot = false;

  environment.etc."euler-system".source = eulerSystem;
}
