# Nix Configuration

Personal Nix setup for macOS (`legendre`) and Linux (`ubuntu-dev`).

## Bootstrap

Prerequisites:

- Nix with flakes enabled
- Git
- On macOS: administrator access and the Xcode command line tools
- On Ubuntu: a user named `ubuntu-dev`, or adjust `flake.nix`

The `legendre` Darwin configuration checks that the Xcode Command Line Tools
are installed and keeps `xcode-select` pointed at
`/Library/Developer/CommandLineTools`. Full Xcode is intentionally not managed
by this flake; remove `Xcode.app` manually if it is installed and you do not
need the IDE, simulators, or platform SDK GUI tooling.

From a fresh checkout, enter the repo and use the matching first-run command
below. The repo includes `nix.conf` so the bootstrap commands can enable flakes
before the managed configuration takes over.

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

## Secrets

Bitwarden-backed env sync is documented in `secrets/README.md`.
