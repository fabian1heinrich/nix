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
- If `wt` is unavailable in the agent shell, use
  `nix shell nixpkgs#worktrunk -c wt ...`.
- Do not rely on `wt` changing directories across agent tool calls; after
  creating or switching worktrees, continue with the command working directory
  set explicitly to the target worktree path.
- Do not create commits unless the user explicitly asks; leave completed agent
  changes uncommitted by default.
- Before cleanup, make sure useful work is committed, merged, or otherwise
  intentionally preserved.

## Repo Layout

- `flake.nix` defines systems, hosts, and development shells.
- `checks.nix` defines the flake checks.
- `hosts/` contains host-specific macOS and Linux configuration.
- `home-manager/` contains user profiles, reusable capability stacks, and
  program configuration.
- `Justfile` is the primary task runner entry point.

## Commands

- List available recipes: `just`
- Format Nix files: `just nix-fmt`
- Evaluate every host on every platform without building: `just nix-eval`
- Build every check native to this platform: `just nix-check`
- Run shellcheck checks: `just nix-shellcheck`
- Run actionlint checks: `just nix-actionlint`
- Check Justfile formatting: `just nix-just`
- Switch the macOS host: `just switch-legendre`
- Switch the Linux Home Manager profile: `just switch-ubuntu-dev`

Run the narrowest relevant checks for the change. For broad Nix or module
changes, prefer `just nix-fmt` and `just nix-check`; run `just nix-shellcheck`
when `.envrc` changes, `just nix-actionlint` when a workflow changes, and
`just nix-just` when the Justfile changes. New files must be `git add`ed
before Nix can see them.

## Conventions

- Follow existing Nix style and module structure.
- Prefer letting a command fail over adding validation. Add a guard only where
  continuing would cause real damage or silently target the wrong thing, and
  put the check in one place rather than at every call site.
- Keep Justfile recipe logic in the Justfile; do not add shell scripts for it.
- Prefer profiles for complete user environments and stacks for reusable
  capabilities. Hosts should select a profile and add host-specific modules.
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
