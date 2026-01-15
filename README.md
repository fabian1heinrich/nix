# Nix Configuration

Personal Nix configuration for macOS (nix-darwin), Ubuntu, and devcontainers.

## Directory Structure

```text
.
├── flake.nix              # Main flake with all system configurations
├── profiles/              # Reusable configuration profiles
│   ├── cli-common.nix     # Basic CLI tools (all hosts)
│   ├── cli-extended.nix   # Extended CLI (workstations)
│   ├── darwin-desktop.nix # macOS desktop profile
│   └── linux-desktop.nix  # Linux desktop profile
├── home-manager/
│   ├── home.nix           # Core home-manager settings
│   ├── default.nix        # Common packages (categorized)
│   └── programs/          # Individual program configurations
└── hosts/
    ├── legendre/          # macOS (Apple Silicon)
    ├── ubuntu-dev/        # Ubuntu workstation
    └── devcontainer/      # VS Code devcontainers
```

## Requirements

- [Nix](https://nixos.org/download.html) (with flakes enabled)
- For macOS: [Homebrew](https://brew.sh/) (managed by nix-darwin)

## Quick Start

### macOS (nix-darwin)

Install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Initial setup:

```bash
export NIX_CONF_DIR=$(pwd)
sudo nix run nix-darwin -- switch --flake .#legendre
```

Subsequent rebuilds:

```bash
sudo darwin-rebuild switch --flake .#legendre
```

### Ubuntu

Initial setup:

```bash
export NIX_CONF_DIR=$(pwd)
nix run nixpkgs#home-manager -- switch --flake .#ubuntu-dev
```

Subsequent rebuilds:

```bash
home-manager switch --flake .#ubuntu-dev
```

### Dev Container

```bash
nix run nixpkgs#home-manager -- switch --flake .#devcontainer
```

## Common Operations

### Update flake inputs

```bash
nix flake update
```

### Format Nix files

```bash
nix fmt
```

### Check configuration

```bash
nix flake check
```

## Adding a New Host

1. Create `hosts/<hostname>/home.nix`
2. Import the appropriate profile from `profiles/`
3. Add host-specific packages and settings
4. Add configuration to `flake.nix`:
   - For macOS: add to `darwinConfigurations`
   - For Linux: add to `homeConfigurations`
5. Add user details to the `users` attrset in `flake.nix`

## Adding a New Program

1. Create `home-manager/programs/<program>.nix`
2. Import it in the appropriate profile or host config

## Troubleshooting

### "experimental-features" error

Ensure flakes are enabled:

```bash
export NIX_CONF_DIR=$(pwd)  # Uses local nix.conf
```
