# Nix Configuration

Personal Nix, nix-darwin, and Home Manager configuration for macOS (`legendre`)
and Linux (`ubuntu-dev`).

## Layout

- `flake.nix`: host inventory, generated outputs, checks, and development shells
- `home-manager/profiles/`: complete user environment profiles
- `home-manager/stacks/`: reusable capability bundles
- `home-manager/programs/`: individual program configuration
- `home-manager/scripts/`: user-facing scripts and tests
- `hosts/<name>/home.nix`: host-specific user configuration
- `hosts/<name>/system.nix`: host-specific system configuration

Hosts select a profile and add only host-specific modules. Profiles compose
stacks, and stacks may build on other stacks.

## Adding a host

Add one entry to `hostSpecs` in `flake.nix` and point its `homeModules`, plus
optional `darwinModules` or `systemModules`, at files under `hosts/<name>/`.
User metadata, platform lists, configurations, apps, and native checks are
derived from that inventory.

## Bootstrap

Requirements are Nix with flakes, Git, and administrator access. macOS also
needs the Xcode Command Line Tools; Ubuntu expects a `ubuntu-dev` user with
`sudo` access unless `flake.nix` is adjusted.

### macOS

From a fresh checkout:

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run .#darwin-rebuild -- switch --flake .#legendre
```

Apply later changes with `just switch-legendre`. The configuration manages the
Command Line Tools selection but not full Xcode. Homebrew upgrades remain
explicit through the `homebrew-upgrade` and `homebrew-upgrade-greedy` recipes.

### Ubuntu

From a fresh checkout:

```bash
export NIX_CONF_DIR=$(pwd)
nix run .#system-manager -- switch --flake .#ubuntu-dev --sudo
nix run .#home-manager -- switch --flake .#ubuntu-dev
```

Apply both system and user changes later with `just switch-ubuntu`.

## Development

Enter the development shell with `nix develop`; list available tasks with
`just`.

## Project-local Podman

Run `direnv allow` after checking out or changing `.envrc`.

### macOS

Homebrew installs Podman, and the containers stack provides its shell
integration on macOS. The project keeps separate rootless and rootful Podman
VMs and matching Docker contexts:

| Mode     | VM / Docker context | Podman connection     |
| -------- | ------------------- | --------------------- |
| Rootless | `podman`            | `podman`              |
| Rootful  | `podman-rootful`    | `podman-rootful-root` |

Rootless is the checked-in default. Create if necessary and start the selected
VM with:

```bash
just podman-start
```

Set `podman_mode=rootful` in the ignored `.env` file and rerun `direnv allow`
to select the rootful VM without dirtying the checkout. `podman-create` and
`podman-stop` operate on the same selection.
`podman-delete` removes every Podman VM and its matching Docker context,
destroying their containers, images, and volumes. These recipes are macOS-only.

Direnv selects the native Podman connection and Docker context. Keep Docker's
persisted global context at `default` so it is restored outside the project:

```bash
env -u DOCKER_CONTEXT docker context use default
```

### Ubuntu

Linux uses native Podman rather than a VM. The host-specific Podman module
installs the runtime, manages the rootless user socket, and configures its
storage. `.envrc` exposes the socket to Docker-compatible tools through
`DOCKER_HOST`; native Podman commands remain daemonless.

Both rootless and rootful storage require `/media/data` to be a real mounted
filesystem. System Manager refuses to prepare Podman storage when it is not
mounted, and Home Manager refuses activation when the rootless storage
directory is unavailable. Apply the System Manager configuration first after
mounting or replacing the data volume.

System Manager installs rootful Podman, Compose, a socket-activated API service,
and the Quadlet generator. Use `podman-rootful` or `podman-rootful compose` for
rootful workloads. Declare long-running rootful containers as Quadlet files
under `environment.etc."containers/systemd/"` in `hosts/ubuntu-dev/system.nix`,
then apply them with `just switch-ubuntu-system`.

## Checks

```bash
just nix-fmt
just nix-eval
just nix-check
just nix-shellcheck
```

`nix-eval` evaluates every host on every configured platform without building.
`nix-check` builds all checks native to the current platform. CI builds the
macOS system and both Ubuntu Home Manager and System Manager configurations,
along with formatting, ShellCheck, and behavioral shell-script tests.
