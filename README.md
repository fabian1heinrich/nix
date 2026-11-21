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

When migrating an existing installation, remove an empty
`/opt/homebrew/Library/Taps` directory once with
`rmdir /opt/homebrew/Library/Taps` before switching. This lets nix-homebrew
replace it with a Nix-managed symlink. If it contains taps, declare and preserve
those before moving the directory aside.

```bash
just switch-legendre
```

Activation installs Homebrew or migrates an existing installation while
preserving installed packages.

Each `just switch-legendre` applies the pinned Nix configuration and upgrades
configured Homebrew formulae, casks (including self-updating and unversioned
casks), and apps listed in `homebrew.masApps`. Mac App Store apps use the latest
available store versions and require being signed in to the App Store.
Activation also uninstalls undeclared Homebrew packages through Bundle cleanup,
which finishes by running `brew cleanup` to remove old versions and cached
downloads using Homebrew's default cleanup policy.
Manual cache cleanup is also available through `just clean-homebrew`. App Store
apps outside `homebrew.masApps` are not upgraded by activation.

Daily maintenance runs through launchd in the `Europe/Berlin` timezone:

| Time | Task |
| --- | --- |
| 03:15 | System profile cleanup and Nix garbage collection with `--delete-older-than 1d` |
| 03:45 | `brew cleanup --prune=all` as `fabian`, pruning cached downloads regardless of age |
| 04:15 | Nix store optimisation to deduplicate identical files |

These jobs run independently of `just switch-legendre`. If the Mac is asleep
at the scheduled time, launchd runs the missed jobs when it wakes.
Run `just clean-nix` to include profiles in your home directory.
Homebrew keeps installed apps and required packages while removing old versions
and downloads.

Nix packages and Homebrew Core and Cask catalogs are pinned in `flake.lock`;
switching alone does not refresh those pins. To update them together and apply:

```bash
just nix-update
just switch-legendre
```

Add any additional taps declaratively in `hosts/legendre/homebrew.nix`;
imperative `brew tap` is disabled.

For a catalog-only refresh, use `nix flake update homebrew-core homebrew-cask`
before switching. Do not run `brew update`: it cannot modify the read-only taps
in the Nix store. nix-homebrew also disables Homebrew's automatic updates.

### Ubuntu

The `ubuntu-dev` user needs `sudo` access. Mount the data volume at `/media/data`
before applying the system configuration; Podman storage requires it.

```bash
just switch-ubuntu
```

Apply both system and user changes later with `just switch-ubuntu`, or use
`just switch-ubuntu-system` and `just switch-ubuntu-dev` separately.
The user and system Nix cleanup timers run daily at midnight and 03:15
respectively, using the same 24-hour cutoff as macOS.

## Development

The applied configuration installs direnv and its shell integration. Open a
new terminal, enter the repository, review `.envrc`, and run `direnv allow`.
It loads `nix.conf` before entering the development shell and reloads when
the settings change.

You can also enter the development shell manually with `nix develop`.
The shell provides `just` and the development tools. Run `just` to list tasks.

## Linux installer builds from Legendre

`hosts/legendre/linux-builder.nix` enables the nix-darwin Linux builder using
`pkgs.darwin.linux-builder-vz`. Its ARM Linux guest uses Rosetta to execute
`x86_64-linux` builds, including the offline workstation ISOs in `byo-nixos`.
The builder retains its writable Nix store across restarts and uses 2 cores,
4 GiB RAM, a 40 GiB sparse disk limit, one build job and one parallel download.
Build scratch files use the writable disk instead of the RAM-backed root filesystem.
Its state is machine-wide,
independent of individual repositories' `.cache/` directories.

The guest runs `nix-collect-garbage --delete-older-than 1d` daily. A separate
NixOS timer trims supported filesystems daily so the sparse VM disk can
release space on the Mac when the virtual disk supports discard.
Its Nix daemon also starts GC below 8 GiB free, aiming to restore 12 GiB free.
Both timers run inside the VM. Disk-pressure GC can reclaim unreferenced build
outputs between scheduled runs. Use `just storage-report` to check the space
the builder disk occupies on the Mac.

Install Rosetta if needed, then apply the Mac configuration:

```bash
softwareupdate --install-rosetta --agree-to-license
just switch-legendre
```

From the deployment repository, `just build-baremetal-iso` then uses this
builder automatically. The target remains `x86_64-linux`; this is execution
through Rosetta, not cross-compilation. The builder does not advertise KVM,
since ARM nested virtualisation cannot accelerate the x86 installer VM. Rehearse
that installer on x86 Linux and commission it on the actual physical host.

For migration from an existing QEMU Linux builder, follow the upstream
[VZ builder documentation](https://github.com/applicative-systems/vzvm) for its
different writable disk format. The 2.54x published speedup compares Rosetta
with QEMU emulation, not with an existing Rosetta-backed Podman builder.

## Storage maintenance

Nix has daily cleanup jobs. Podman VM deletion and VS Code cache cleanup
run only when invoked.

`just clean` runs all five cleanups on macOS. Quit VS Code and its updater
first. The final step permanently deletes every Podman VM and its data
without prompting. On Linux, `just clean` runs `clean-nix`.

```bash
just storage-report                        # Five labeled sizes in GiB
just storage-report-nix                    # Optional slow scan of /nix/store
just storage-roots                         # List Nix GC roots
just storage-why /nix/store/…               # Explain why a store path is retained
just clean-nix                             # One-day profile cleanup, store GC and optimisation
just clean-builder                         # Collect unreachable paths in the Linux builder now
just clean-podman                          # Permanently delete all macOS Podman VMs and their data
just clean-vscode                          # Quit VS Code and its updater first
just clean-homebrew                        # Homebrew's native cleanup
```

`clean-nix` runs `nix-collect-garbage --delete-older-than 1d` as the
current user and as root, then deduplicates the store. Nix keeps the current
generation, generations from the past 24 hours, and the most recent generation
before the cutoff. A live `result` link or direnv GC root keeps its dependencies
regardless of age. GC can reclaim any unreachable store object immediately.
Nix's download and lookup cache settings control when it checks for fresh data.
Files in the user cache can remain on disk beyond 24 hours.

`just clean-builder` uses the Mac's root-owned builder SSH key to run
`nix-store --gc` as the guest's `builder` user. Guest profile pruning and
filesystem trim run on their daily timers.

`clean-podman` runs `podman-delete`. It forcibly removes every running or
stopped Podman VM and its disk, including containers, images, pods, and
volumes in both rootful and rootless storage. It also removes each VM's
matching Docker context. There is no age filter or confirmation prompt.
`just podman-create` creates a fresh VM when needed.

`clean-vscode` removes only `Cache`, `Code Cache`, `GPUCache`, `CachedData`,
`WebStorage/*/CacheStorage`, and the `com.microsoft.VSCode.ShipIt` updater cache.
It refuses to run while VS Code or its updater is running. Settings, extensions,
workspace/global state, local history, other web storage, and unsaved backups
are preserved.

`clean-homebrew` uses `brew cleanup --prune=all`. Other Library caches are left alone.
Commands fail normally on missing tools or inaccessible paths.
`storage-report` uses `df` for the Nix filesystem rather than walking every store
file. This reports filesystem usage, not the exact size of `/nix/store`.
It prints one labeled size per area in GiB, without command traces or VM details.
Missing directories count as zero.
The cache total covers readable files only; protected-cache errors are suppressed.
Use `storage-report-nix` for an exact directory scan; its first result can take
a minute or longer on a large store.
Just's `[macos]` attribute limits the Mac-specific recipes to macOS;
`clean-nix`, `storage-report-nix`, `storage-roots`, and `storage-why`
also work on Linux.

## Checks

```bash
just nix-fmt        # Format Nix files
just nix-eval       # Evaluate every host on every platform without building
just nix-check      # Build all checks native to the current platform
just nix-shellcheck # Check .envrc
just nix-actionlint # Check GitHub Actions workflows
just check-justfile # Check Justfile formatting
```

CI uses one Linux job to evaluate every host configuration, check formatting,
and lint shell scripts, workflows, the Justfile, and the generated Linux zshrc.
Full host builds run locally with `just nix-check` or when applying a configuration.

Stage new files with `git add` before running Nix so the flake can see them.
Update dependencies only when intended with `just nix-update`.

## Reusable Home Manager modules

`homeModules` exports every top-level `.nix` file in `home-manager/programs/`
(except its index) and each program directory containing `default.nix`, including
`vscode/`. For example, another flake can select
`imports = with nixRepo.homeModules; [ core zsh fzf git helix tmux ];`.
Exports make modules available; only imported modules apply their settings.
Program filenames determine export names, so keep them stable and put helpers
inside program directories. Non-Nix assets are ignored by discovery.

`core` supplies shared home settings and uses the caller's `userConfig`.
`gnome-settings` supplies desktop preferences without the complete GNOME profile.
The existing `gnome` and `workstation` exports remain complete profiles.
Importing these modules does not apply the source overlay; add it only when
selected packages need it. Program modules own their helper packages and shell
integrations: FZF supplies its previews/completions and fzf-tab, Helix selects
the command-line editor, Git supplies its Oh My Zsh plugin, and Worktrunk sets
up its shell integration. Broot uses Home Manager's native shell integration.

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
