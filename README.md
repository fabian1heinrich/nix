# Nix Configuration

Personal Nix setup for macOS (`legendre`), Ubuntu (`ubuntu-dev`), and NixOS (`euler`).

## Bootstrap

Prerequisites:

- Nix with flakes enabled
- Git
- On macOS: administrator access and the Xcode command line tools
- On Ubuntu: a user named `ubuntu-dev`, or adjust `users.nix`
- For the Euler installer VM: KVM-capable Linux for acceleration; software emulation also works

From a fresh checkout, enter the repo and use the matching first-run command
below. The repo includes `nix.conf` so the bootstrap commands can enable flakes
before the managed configuration takes over.

## Structure

- `profiles/base.nix`: minimal shared baseline
- `profiles/desktop.nix`: shared desktop baseline
- `home-manager/stacks/*.nix`: workflow bundles
- `hosts/<name>/home.nix`: host-specific additions
- `hosts/<name>/nixos.nix`: NixOS host configuration, where applicable

Hosts compose local profiles and role stacks.

## Apply

macOS (`legendre`, first bootstrap):

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#legendre
```

macOS (`legendre`, regular updates):

```bash
sudo darwin-rebuild switch --flake .#legendre
```

Homebrew app updates are intentionally kept out of `darwin-rebuild` activation so rebuilds stay fast and predictable. Run them explicitly when you want to update Homebrew-managed apps:

```bash
brew update
brew upgrade
brew upgrade --cask
brew upgrade --cask --greedy
mas upgrade
```

Ubuntu (`ubuntu-dev`, first run):

```bash
export NIX_CONF_DIR=$(pwd)
nix run github:nix-community/home-manager -- switch --flake .#ubuntu-dev
```

Ubuntu (`ubuntu-dev`, after setup):

```bash
home-manager switch --flake .#ubuntu-dev
```

NixOS test installer (`euler-vm` target):

Build the VM-oriented installer ISO on a connected `x86_64-linux` machine:

```bash
just build-euler-vm-iso
```

The recipe prints the ISO path in the Nix store and does not create a `result`
symlink.

Start a local QEMU VM from the same ISO:

```bash
just run-euler-vm
```

The VM launcher creates a persistent qcow2 disk and UEFI vars below
`.euler-vm/`, disables networking by default, and boots the ISO with KVM when
available. Useful overrides:

```bash
EULER_VM_MEMORY=8192 EULER_VM_CPUS=6 just run-euler-vm
EULER_VM_DISK_SIZE=128G just run-euler-vm
EULER_VM_NET=user just run-euler-vm
EULER_VM_ISO=/path/to/euler-vm-installer.iso just run-euler-vm
EULER_VM_DISPLAY=nographic just run-euler-vm
```

Inside the installer VM, prepare the target disk with the baked `disko` layout,
then install the baked `euler` system closure from the ISO:

```bash
sudo prepare-euler-disk /dev/vda
sudo install-euler
```

After `install-euler` finishes successfully, shut down the installer VM and boot
from the installed qcow2 disk to see the graphical GNOME login:

```bash
EULER_VM_BOOT=disk EULER_VM_DISPLAY=gtk just run-euler-vm
```

`EULER_VM_BOOT=disk` is only for the post-install boot. Before the installation
has completed, keep the default ISO boot by running `just run-euler-vm`.
Disk boots reuse the existing qcow2 disk and do not require an installer ISO.
`EULER_VM_DISPLAY=gtk` opens the graphical QEMU window; `nographic` only shows
the serial console.

The VM target uses LVM on LUKS: GPT partition `euler-luks`, LUKS mapper
`euler-crypt`, volume group `euler`, root LV `root`, root filesystem label
`nixos`, and EFI filesystem label `boot`. The layout is declared in
`hosts/euler/storage.nix`; `prepare-euler-disk` runs `disko` and mounts it
below `/mnt`. The installed system hostname is `euler`.

NixOS real machine (`euler-baremetal` target):

Build the bare-metal installer ISO on a connected `x86_64-linux` machine:

```bash
just build-euler-baremetal-iso
```

On `x86_64-linux`, build the same bootable installer ISO and write it directly
to a USB drive by identifying the whole USB disk first, then passing that
whole-disk device to the USB writer recipe:

```bash
just list-usb-drives
just write-euler-iso-usb /dev/sdX
```

Use the whole disk, such as `/dev/sdX` or `/dev/nvmeXnY`, not a partition such
as `/dev/sdX1`. The recipe prints the selected device, asks for `YES`, unmounts
mounted partitions, writes the hybrid ISO image, flushes it, and leaves the USB
drive ready to boot on the target machine.

Boot that ISO on the target machine, choose the install disk with `lsblk`,
prepare it with the baked `disko` layout, and install the baked `euler` system
closure:

```bash
sudo prepare-euler-disk /dev/nvme0n1
sudo install-euler
```

`prepare-euler-disk` creates the same LVM-on-LUKS layout as the VM target and
mounts it below `/mnt`. Pass the whole target disk, such as `/dev/sda`,
`/dev/nvme0n1`, or a stable `/dev/disk/by-id/...` path, not a partition.

`install-euler` also copies an editable snapshot of this flake to the installed
system at `/home/euler/nix-config`. After booting the installed machine, make
small local configuration tweaks there and apply them with:

```bash
cd /home/euler/nix-config
sudo nixos-rebuild switch --flake .#euler-baremetal
```

After the first successful boot, generate and commit the real hardware config
without filesystem entries, because `hosts/euler/storage.nix` remains the
declarative owner of the disk layout:

```bash
sudo nixos-generate-config --no-filesystems --root /
cp /etc/nixos/hardware-configuration.nix /home/euler/nix-config/hosts/euler/hardware-configuration.nix
sudo nixos-rebuild switch --flake /home/euler/nix-config#euler-baremetal
```

`euler-baremetal` imports `hosts/euler/hardware-configuration.nix` when that
file exists. The repo target is named `euler-baremetal`, but the installed
system hostname is `euler`. The first local login for the `euler` user uses the
temporary password `euler`; change it after the first boot with `passwd`.

## Dev Shells

```bash
nix develop
```

## Checks

Fast evaluation check:

```bash
just nix-check
```

Format and script checks:

```bash
just nix-fmt
nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck
```

Native build checks are exposed as flake checks on their matching platform:

- macOS: `checks.aarch64-darwin.legendre-system-build`
- Ubuntu: `checks.x86_64-linux.ubuntu-dev-activation-build`
- NixOS VM: `checks.x86_64-linux.euler-vm-system-build`
- NixOS bare metal: `checks.x86_64-linux.euler-baremetal-system-build`

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
