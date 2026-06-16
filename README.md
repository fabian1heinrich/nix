# Nix Configuration

Personal Nix setup for macOS (`legendre`), Ubuntu (`ubuntu-dev`), and NixOS (`euler`).

## Bootstrap

Prerequisites:

- Nix with flakes enabled
- Git
- On macOS: administrator access and the Xcode command line tools
- On Ubuntu: a user named `ubuntu-dev`, or adjust `users.nix`
- For the `euler` ISO VM: KVM-capable Linux for acceleration; software emulation also works

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

NixOS (`euler`, installer ISO):

Build the airgapped installer ISO on a connected `x86_64-linux` machine:

```bash
just build-euler-iso
```

The ISO is written below `result/iso/`.

Start a local QEMU VM from the same ISO:

```bash
just run-euler-iso-vm
```

The VM launcher creates a persistent qcow2 disk and UEFI vars below
`.euler-vm/`, disables networking by default, and boots the ISO with KVM when
available. Useful overrides:

```bash
EULER_VM_MEMORY=8192 EULER_VM_CPUS=6 just run-euler-iso-vm
EULER_VM_DISK_SIZE=128G just run-euler-iso-vm
EULER_VM_NET=user just run-euler-iso-vm
```

Inside the installer VM, create and mount target filesystems below `/mnt`, then
install the baked `euler` system closure from the ISO:

```bash
sudo nixos-install --root /mnt --system /etc/euler-system --no-channel-copy
```

The generic `euler` host config expects the root filesystem to be labeled
`nixos`. The first local login for the `euler` user uses the temporary password
`euler`; change it after the first boot with `passwd`.

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
- NixOS: `checks.x86_64-linux.euler-system-build`

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
