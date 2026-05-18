# Nix Configuration

Personal Nix setup for macOS (`legendre`) and Linux (`ubuntu-dev`).

## Structure

- `profiles/base.nix`: minimal shared baseline
- `profiles/desktop.nix`: shared desktop baseline
- `home-manager/stacks/*.nix`: workflow bundles
- `hosts/<name>/home.nix`: host-specific additions

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

## Proxmox Cloud Image

Build a NixOS VMA template image for Proxmox:

```bash
just build-proxmox-cloud
```

Run the build on an `x86_64-linux` machine, such as `ubuntu-dev` or Proxmox itself, unless your macOS machine has a remote Linux builder configured.

The image is written to `result/`. Copy the `vzdump-qemu-*.vma.zst` file to a Proxmox dump storage path, restore it as a template VM, then clone it with cloud-init values:

```bash
scp result/vzdump-qemu-*.vma.zst root@proxmox:/var/lib/vz/dump/
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-cloud-template.vma.zst 9000 --unique true
qm template 9000

qm clone 9000 101 --name nixos-test
qm set 101 --ciuser nixos
qm set 101 --sshkey ~/.ssh/id_ed25519.pub
qm set 101 --ipconfig0 ip=dhcp
qm start 101
```

## Dev Shells

```bash
nix develop
nix develop .#kubernetes
```

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
