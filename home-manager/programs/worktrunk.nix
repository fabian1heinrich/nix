{ ... }:
{
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize }}"

    [list]
    full = true
    branches = true

    [switch]
    cd = true
  '';
}
