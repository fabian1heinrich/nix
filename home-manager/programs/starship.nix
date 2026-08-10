{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "([╭─](dimmed white) $direnv$nix_shell$custom$python$docker_context$kubernetes\n[╰─](dimmed white) )$username$hostname$directory$git_branch$git_status$cmd_duration$character";
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
        truncation_length = 20;
        truncation_symbol = "";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
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
      kubernetes = {
        symbol = "🪐";
        disabled = false;
        format = "[$symbol$context]($style)([\\($namespace\\)](cyan)) ";
        detect_files = [
          "kustomization.yaml"
          "values.yaml"
          "zarf.yaml"
        ];
        detect_folders = [
          "k8s"
          "kubernetes"
          "manifests"
          "charts"
        ];
      };
      docker_context = {
        symbol = "📦";
        format = "[$symbol$context]($style) ";
        style = "blue bold";
        disabled = pkgs.stdenv.isLinux;
        only_with_files = true;
        detect_files = [
          "Containerfile"
          "Dockerfile"
          "compose.yml"
          "compose.yaml"
          "podman-compose.yml"
          "podman-compose.yaml"
          "docker-compose.yml"
          "docker-compose.yaml"
        ];
        detect_folders = [
          ".devcontainer"
        ];
      };
    };
  };
}
