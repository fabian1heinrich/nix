# Nix Configuration

Personal Nix, nix-darwin, and Home Manager configuration for macOS (`legendre`)
and Linux (`ubuntu-dev`).

## Layout

- `flake.nix`: host inventory, generated outputs, and development shells
- `checks.nix`: how the flake checks are built
- `home-manager/profiles/`: complete user environment profiles
- `home-manager/stacks/`: reusable capability bundles
- `home-manager/programs/`: individual program configuration
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

Create if necessary and start a VM with the mode as its argument, rootless by
default:

```bash
just podman-create
just podman-create rootful
```

Starting a VM stops whichever other machine is running, since only one may
forward the Docker API socket, so switching modes is just the other invocation.
`podman-delete` removes every Podman VM and its matching Docker context,
destroying their containers, images, and volumes. Both recipes are macOS-only.

The recipes share one mode lookup through the `select_machine` variable, so an
unsupported mode fails there rather than falling back to the rootless machine.

Direnv follows whichever machine is running, so `podman-create` needs no second
declaration of the mode anywhere; it exports that machine's Podman connection
and Docker context, and watches Podman's machine directory so creating or
removing a VM reloads the environment. With no machine running it falls back to
the first one, which leaves the prompt reporting the socket as asleep rather
than dropping its Podman module. Keep Docker's persisted global context at
`default` so it is restored outside the project:

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
mounted, so it never seeds the store onto the root filesystem, and the user
socket and API service carry `ConditionPathIsMountPoint` so they do not start
against a missing volume. Apply the System Manager configuration first after
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
just nix-actionlint
just nix-just
```

`nix-eval` evaluates every host on every configured platform without building.
`nix-check` builds all checks native to the current platform.

Beyond the host configurations, the flake checks cover formatting (`nix fmt
-- --ci`), ShellCheck over `.envrc`, actionlint over the
workflows, `just --fmt --check` over the Justfile, and `zsh -n` over each
host's generated `.zshrc`, so a syntax error in `programs/zsh.nix` fails the
build rather than the next login shell.

CI runs `nix flake check --all-systems --no-build` once and `nix flake check`
on each runner. Without `--all-systems` that builds exactly the checks native
to the runner, so adding a host to `flake.nix` needs no workflow change. The
`zsh -n` check is native-only because the generated `.zshrc` is built by its
own host's `pkgs`.

Runtime guards are deliberately sparse: the configuration only refuses to
proceed where continuing would write to the wrong place or silently pick the
wrong target, and otherwise lets the underlying tool fail on its own.
