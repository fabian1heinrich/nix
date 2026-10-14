{ ... }:
{
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize }}"

    [list]
    full = true
    branches = false
    json-schema = 2

    [switch]
    cd = true
  '';
}
