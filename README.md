# Nix Configuration

Personal Nix, nix-darwin, and Home Manager configuration for macOS (`legendre`)
and Linux (`ubuntu-dev`).

## Layout

- `flake.nix`: systems, hosts, checks, and development shells
- `profiles/`: shared base and desktop profiles
- `home-manager/`: reusable programs, stacks, and scripts
- `hosts/<name>/home.nix`: host-specific user configuration
- `hosts/<name>/system.nix`: host-specific system configuration

Hosts compose shared profiles with role-specific stacks.

## Bootstrap

Requirements are Nix with flakes, Git, and administrator access. macOS also
needs the Xcode Command Line Tools; Ubuntu expects a `ubuntu-dev` user with
`sudo` access unless `flake.nix` is adjusted.

### macOS

From a fresh checkout:

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#legendre
```

Apply later changes with `just switch-legendre`. The configuration manages the
Command Line Tools selection but not full Xcode. Homebrew upgrades remain
explicit through the `homebrew-upgrade` and `homebrew-upgrade-greedy` recipes.

### Ubuntu

From a fresh checkout:

```bash
export NIX_CONF_DIR=$(pwd)
nix run .#system-manager -- switch --flake .#ubuntu-dev --sudo
nix run github:nix-community/home-manager -- switch --flake .#ubuntu-dev
```

Apply both system and user changes later with `just switch-ubuntu`.

## Development

Enter the development shell with `nix develop`; list available tasks with
`just`.

## Project-local Podman

Run `direnv allow` after checking out or changing `.envrc`.

### macOS

The project keeps separate rootless and rootful Podman VMs and matching Docker
contexts:

| Mode     | VM / Docker context | Podman connection     |
| -------- | ------------------- | --------------------- |
| Rootless | `podman`            | `podman`              |
| Rootful  | `podman-rootful`    | `podman-rootful-root` |

Rootless is the checked-in default. Create if necessary and start the selected
VM with:

```bash
just podman-start
```

Set `podman_mode=rootful` in `.envrc` and rerun `direnv allow` to select the
rootful VM. `podman-create`, `podman-stop`, and `podman-delete` operate on the
same selection. Deleting a VM also removes its Docker context and destroys its
containers, images, and volumes. These recipes are macOS-only.

Direnv selects the native Podman connection and Docker context. Keep Docker's
persisted global context at `default` so it is restored outside the project:

```bash
env -u DOCKER_CONTEXT docker context use default
```

### Ubuntu

Linux uses native Podman rather than a VM. Home Manager manages the rootless
user socket, and `.envrc` exposes it to Docker-compatible tools through
`DOCKER_HOST`; native Podman commands remain daemonless.

System Manager installs rootful Podman, Compose, a socket-activated API service,
and the Quadlet generator. Use `podman-rootful` or `podman-rootful compose` for
rootful workloads. Declare long-running rootful containers as Quadlet files
under `environment.etc."containers/systemd/"` in `hosts/ubuntu-dev/system.nix`,
then apply them with `just switch-ubuntu-system`.

## Checks

```bash
just nix-fmt
just nix-check
just nix-shellcheck
```

Native flake checks cover the macOS system build and both Ubuntu Home Manager
and System Manager builds.

## Secrets

Bitwarden-backed environment synchronization is documented in
`secrets/README.md`.
