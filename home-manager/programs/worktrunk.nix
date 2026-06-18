{ ... }:
{
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize_hash }}"

    [list]
    full = true
    branches = true

    [switch]
    cd = true
  '';
}
