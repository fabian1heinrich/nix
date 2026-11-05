{
  config,
  lib,
  ...
}:
{
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize }}"

    [aliases]
    # Worktrunk treats bare "cat" as unset and falls back to less.
    commit-preview = "GIT_PAGER='cat -' wt step commit --dry-run {{ args }}"

    [commit.generation]
    command = "${lib.getExe config.programs.codex.package} exec --ephemeral --sandbox=read-only -m gpt-5.6-luna -c model_reasoning_effort=low -"

    [merge]
    ff = false
    squash = false

    [list]
    full = true
    branches = false
    json-schema = 2

    [switch]
    cd = true
  '';
}
