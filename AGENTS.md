# Repository Guidance

This repository contains Fabian's Nix, nix-darwin, and Home Manager
configuration. Keep changes small, explicit, and easy to review.

## Worktree Workflow

- Use one Worktrunk worktree per task.
- Do not make agent changes in the default-branch trunk checkout.
- Do not edit sibling worktrees unless the user explicitly asks.
- Treat each Codex thread as owning only the worktree it was started in.
- Prefer `wt switch --create <branch>` for new work and `wt merge` or a PR flow
  when the change is ready.
- Do not create commits unless the user explicitly asks; leave completed agent
  changes uncommitted by default.
- Before cleanup, make sure useful work is committed, merged, or otherwise
  intentionally preserved.

## Repo Layout

- `flake.nix` defines systems, hosts, checks, and development shells.
- `hosts/` contains host-specific macOS and Linux configuration.
- `home-manager/` contains shared user configuration, programs, stacks, and
  scripts.
- `Justfile` is the primary task runner entry point.

## Commands

- List available recipes: `just`
- Format Nix files: `just nix-fmt`
- Run flake evaluation checks: `just nix-check`
- Run shellcheck checks: `just nix-shellcheck`
- Switch the macOS host: `just switch-legendre`
- Switch the Linux Home Manager profile: `just switch-ubuntu-dev`

Run the narrowest relevant checks for the change. For broad Nix or module
changes, prefer `just nix-fmt` and `just nix-check`; run `just nix-shellcheck`
when shell scripts change.

## Conventions

- Follow existing Nix style and module structure.
- Prefer shared Home Manager modules for reusable user configuration.
- Keep host-specific behavior under the relevant `hosts/<name>/` directory.
- Do not update `flake.lock` unless the task is specifically about dependency
  updates or the change requires it.
- Do not commit secrets, local environment files, or machine-specific scratch
  files.

## Done Criteria

- The change is scoped to the requested task.
- Formatting has been run when Nix files changed.
- Relevant checks have been run, or the reason they were skipped is reported.
- Any unrelated dirty worktree changes are left untouched.
