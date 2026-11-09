# Nix Configuration

Personal Nix, nix-darwin, and Home Manager configuration for macOS (`legendre`)
and Linux (`ubuntu-dev`).

## Getting started

Requirements are Nix, Git, and administrator access. macOS also needs the
Xcode Command Line Tools. The configured hosts are Apple Silicon
macOS (`fabian`) and x86_64 Ubuntu (`ubuntu-dev`); adjust `hostSpecs` in
`flake.nix` and the host modules before applying this to another machine.

From the repository root, enter the development shell, then apply the
configuration for your operating system below. This works before direnv or
`just` is installed:

```bash
nix --extra-experimental-features 'nix-command flakes' develop
```

The shell provides `just` and loads the settings from `nix.conf` automatically.

### macOS

```bash
just switch-legendre
```

Activation installs Homebrew or migrates an existing installation while
preserving installed packages.

Apply later changes with `just switch-legendre`. Upgrade Homebrew packages
explicitly with `just homebrew-upgrade` or `just homebrew-upgrade-greedy`.

### Ubuntu

The `ubuntu-dev` user needs `sudo` access. Mount the data volume at `/media/data`
before applying the system configuration; Podman storage requires it.

```bash
just switch-ubuntu
```

Apply both system and user changes later with `just switch-ubuntu`, or use
`just switch-ubuntu-system` and `just switch-ubuntu-dev` separately.

## Development

The applied configuration installs direnv and its shell integration. Open a
new terminal, enter the repository, review `.envrc`, and run `direnv allow`.
It loads `nix.conf` before entering the development shell and reloads when
the settings change.

You can also enter the development shell manually with `nix develop`.
The shell provides `just` and the development tools. Run `just` to list tasks.

## Checks

```bash
just nix-fmt        # Format Nix files
just nix-eval       # Evaluate every host on every platform without building
just nix-check      # Build all checks native to the current platform
just nix-shellcheck # Check .envrc
just nix-actionlint # Check GitHub Actions workflows
just nix-just       # Check Justfile formatting
```

Stage new files with `git add` before running Nix so the flake can see them.
Update dependencies only when intended with `just nix-update`.

## Containers

The `.envrc` also configures project-local Docker/Podman connections.

On macOS, Homebrew supplies Podman. Create or start a VM with:

```bash
just podman-create         # Rootless (default)
just podman-create rootful # Rootful; stops the other VM
```

Direnv follows the running VM. Keep Docker's global context at `default` with
`env -u DOCKER_CONTEXT docker context use default`.
`just podman-delete` deletes **all** Podman VMs, their containers, images,
volumes, and matching Docker contexts.

Ubuntu uses native Podman with a rootless user socket; `.envrc` sets
`DOCKER_HOST` for Docker-compatible tools. Use `podman-rootful` or
`podman-rootful compose` for rootful workloads.

## Layout

- `flake.nix`: host inventory, outputs, and development shells
- `checks.nix`: flake checks
- `hosts/<name>/`: host-specific user and system modules
- `home-manager/profiles/`: complete user environments
- `home-manager/stacks/`: reusable capabilities composed by profiles
- `home-manager/programs/`: individual program configuration
- `Justfile`: build, check, switch, and maintenance commands

To add a host, add its modules under `hosts/<name>/` and a `hostSpecs` entry
in `flake.nix` selecting those modules and a Home Manager profile.
