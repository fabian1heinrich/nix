{
  config,
  eulerConfigSource,
  eulerDiskoConfig,
  eulerDiskoScript,
  eulerFlakeInputSources,
  eulerInstallDisk,
  eulerInstallerName,
  eulerSystem,
  eulerUserConfig,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  prepareEulerDisk = pkgs.writeShellApplication {
    name = "prepare-euler-disk";
    runtimeInputs = with pkgs; [
      coreutils
      cryptsetup
      dosfstools
      e2fsprogs
      gptfdisk
      lvm2
      parted
      systemd
      util-linux
    ];
    text = ''
      usage() {
        echo "Usage: prepare-euler-disk [--yes] ${eulerInstallDisk}"
      }

      assume_yes=0
      if [ "$#" -gt 0 ] && [ "$1" = "--yes" ]; then
        assume_yes=1
        shift
      fi

      if [ "$#" -ne 1 ]; then
        usage >&2
        exit 2
      fi

      disk="$1"

      if [ "$(id -u)" -ne 0 ]; then
        echo "prepare-euler-disk must run as root." >&2
        exit 1
      fi

      if [ ! -b "$disk" ]; then
        echo "Not a block device: $disk" >&2
        exit 1
      fi

      if mountpoint -q /mnt || mountpoint -q /mnt/boot; then
        echo "Unmount /mnt and /mnt/boot before preparing a disk." >&2
        exit 1
      fi

      if [ "$assume_yes" -ne 1 ]; then
        echo "This will destroy all data on $disk."
        printf 'Type YES to continue: '
        read -r confirmation
        if [ "$confirmation" != "YES" ]; then
          echo "Aborted." >&2
          exit 1
        fi
      fi

      canonical_disk="$(readlink -f "$disk")"
      expected_disk="$(readlink -f "${eulerInstallDisk}")"

      if [ "$canonical_disk" != "$expected_disk" ]; then
        echo "This installer was built to prepare ${eulerInstallDisk}, not $disk." >&2
        echo "Refusing to run the baked disko script against an unexpected disk." >&2
        exit 1
      fi

      ${pkgs.bash}/bin/bash ${eulerDiskoScript}/bin/disko-destroy-format-mount --yes-wipe-all-disks

      echo "Euler disk layout is ready. Run: install-euler"
    '';
  };

  installEuler = pkgs.writeShellApplication {
    name = "install-euler";
    runtimeInputs = with pkgs; [
      coreutils
      cryptsetup
      lvm2
      nix
      util-linux
    ];
    text = ''
      if [ "$#" -gt 1 ]; then
        echo "Usage: install-euler [root]" >&2
        exit 2
      fi

      root="''${1:-/mnt}"

      mount_euler_layout() {
        local luks_part="/dev/disk/by-partlabel/euler-luks"
        local root_lv="/dev/euler/root"

        if mountpoint -q "$root"; then
          return 0
        fi

        echo "Target root is not mounted: $root" >&2
        echo "Attempting to mount the prepared Euler disk layout." >&2

        if [ ! -b "$root_lv" ]; then
          if [ ! -e /dev/mapper/euler-crypt ] && [ -b "$luks_part" ]; then
            if ! cryptsetup isLuks "$luks_part"; then
              echo "Found $luks_part, but it does not contain a LUKS header." >&2
              echo "The disk appears to have been partitioned but not fully prepared." >&2
              echo "Re-run prepare-euler-disk for the install disk, for example:" >&2
              echo "  sudo prepare-euler-disk ${eulerInstallDisk}" >&2
              return 1
            fi
            cryptsetup open "$luks_part" euler-crypt
          fi
          vgchange --activate y euler >/dev/null 2>&1 || true
        fi

        if [ -b "$root_lv" ]; then
          mkdir -p "$root"
          mount "$root_lv" "$root"
        fi
      }

      if [ ! -d "$root" ]; then
        echo "Target root does not exist: $root" >&2
        exit 1
      fi

      if ! mountpoint -q "$root"; then
        mount_euler_layout
      fi

      if ! mountpoint -q "$root"; then
        echo "Could not mount the target root at $root." >&2
        echo "Run prepare-euler-disk first, or mount the target root manually." >&2
        exit 1
      fi

      mkdir -p "$root/boot"
      if ! mountpoint -q "$root/boot"; then
        if [ -b /dev/disk/by-label/boot ]; then
          mount /dev/disk/by-label/boot "$root/boot"
        else
          echo "Target boot filesystem is not mounted: $root/boot" >&2
          exit 1
        fi
      fi

      ${config.system.build.nixos-install}/bin/nixos-install \
        --root "$root" \
        --system "${eulerSystem}" \
        --no-channel-copy \
        --no-root-password \
        --option substituters ""

      config_target="${eulerUserConfig.homeDirectory}/nix-config"
      target_config="$root$config_target"
      if [ -e "$target_config" ]; then
        echo "Leaving existing config repo in place: $config_target"
      else
        mkdir -p "$(dirname "$target_config")"
        cp -a "${eulerConfigSource}" "$target_config"
        chmod -R u+w "$target_config"

        if [ -d "$root${eulerUserConfig.homeDirectory}" ]; then
          chown --reference="$root${eulerUserConfig.homeDirectory}" "$target_config" || true
          chown -R --reference="$root${eulerUserConfig.homeDirectory}" "$target_config" || true
        else
          chown -R 1000:100 "$target_config" || true
        fi

        echo "Copied editable config repo to $config_target"
      fi

      nix --extra-experimental-features 'nix-command flakes' flake archive \
        --to "$root" \
        --offline \
        --no-write-lock-file \
        "$target_config"
    '';
  };
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  image.baseName = lib.mkForce eulerInstallerName;

  isoImage = {
    storeContents = eulerFlakeInputSources ++ [
      eulerSystem
    ];
  };

  boot.zfs.forceImportRoot = false;
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  environment.etc."euler-system".source = eulerSystem;
  environment.etc."euler-disko.nix".source = eulerDiskoConfig;
  environment.systemPackages = [
    installEuler
    prepareEulerDisk
  ];
}
