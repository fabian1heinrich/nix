{ pkgs, ... }:
let
  containerProjectFiles = [
    "Containerfile"
    "Dockerfile"
    "compose.yml"
    "compose.yaml"
    "podman-compose.yml"
    "podman-compose.yaml"
    "docker-compose.yml"
    "docker-compose.yaml"
  ];
in
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # Allow brief Git startup delays after development-shell updates.
      command_timeout = 1000;
      format = "([╭─](dimmed white) $direnv$mise$nix_shell$python$custom$kubernetes\n[╰─](dimmed white) )$username$hostname$directory\${custom.git_worktree}$git_branch$git_state$git_status$character";
      right_format = "$status$cmd_duration";
      username = {
        format = "[$user]($style)[@]($style)";
        disabled = false;
        show_always = true;
        style_user = "bold green";
      };
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol]($style)[$hostname]($style) ";
        disabled = false;
        ssh_symbol = "🌍";
        trim_at = ".";
        style = "bold green";
      };
      git_branch = {
        symbol = "🌱";
        truncation_length = 40;
        truncation_symbol = "…";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };
      custom.git_worktree = {
        description = "Linked Git worktree";
        require_repo = true;
        shell = [ "sh" ];
        # Linked worktrees have their own Git directory but share the common directory.
        when = ''
          git rev-parse --path-format=absolute --git-dir --git-common-dir | {
            IFS= read -r git_dir
            IFS= read -r common_dir
            test "$git_dir" != "$common_dir"
          }
        '';
        symbol = "🌳";
        style = "bold green";
        format = "[$symbol]($style) ";
      };
      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "bold red";
        conflicted = "!";
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕$ahead_count/$behind_count";
        up_to_date = "";
        untracked = "?";
        stashed = "\\$";
        modified = "~";
        staged = "+";
        renamed = ">";
        deleted = "x";
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };
      status = {
        disabled = false;
        pipestatus = true;
        format = "[$symbol$status]($style) ";
        symbol = "✘";
        pipestatus_format = "[\\[$pipestatus\\]]($style) ";
        pipestatus_segment_format = "$status";
      };
      cmd_duration = {
        min_time = 1000;
        format = "[$duration]($style) ";
        style = "yellow";
      };
      python = {
        symbol = "🐍";
        style = "yellow bold";
        format = "[$symbol $version( $virtualenv)]($style) ";
        version_format = "v$major.$minor";
      };
      nix_shell = {
        format = "[$symbol$name]($style) ";
        symbol = "❄️ ";
        style = "bold blue";
      };
      direnv = {
        disabled = false;
        format = "[$symbol]($style) ";
        style = "bold yellow";
        symbol = "🌿";
      };
      mise = {
        disabled = false;
        format = "[$symbol]($style) ";
        style = "bold purple";
        symbol = "🔪";
      };
      kubernetes = {
        # kubectl works from any directory; show the selected context there too.
        symbol = "🪐";
        disabled = false;
        format = "[$symbol$context]($style)([\\($namespace\\)](cyan)) ";
      };
      docker_context.disabled = true;
      custom.docker_context = {
        disabled = pkgs.stdenv.hostPlatform.isLinux;
        detect_files = containerProjectFiles;
        detect_folders = [ ".devcontainer" ];
        shell = [ "sh" ];
        # .envrc resolves the socket; probe it once and color the result here.
        # Keep Starship's default output escaping enabled for the context name.
        command = ''
          [ -n "''${DOCKER_CONTEXT:-}" ] || exit 1
          if curl --silent --fail --max-time 0.1 --unix-socket "''${PODMAN_SOCKET:-}" http://localhost/_ping >/dev/null 2>&1; then
            printf '\033[1;34m📦%s\033[0m' "$DOCKER_CONTEXT"
          else
            printf '\033[1;31m📦💤%s\033[0m' "$DOCKER_CONTEXT"
          fi
        '';
        format = "($output )";
      };
    };
  };
}
