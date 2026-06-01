{
  lib,
  ...
}:
let
  containerFiles = [
    "Containerfile"
    "Dockerfile"
    "compose.yml"
    "compose.yaml"
    "podman-compose.yml"
    "podman-compose.yaml"
    "docker-compose.yml"
    "docker-compose.yaml"
  ];
  containerFileTest = lib.concatMapStringsSep " || " (
    file: "[[ -e ${lib.escapeShellArg file} ]]"
  ) containerFiles;
in
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$username$hostname($directory)($kubernetes)($docker_context)(\${custom.podman_context})($python)($git_branch)($git_status)($cmd_duration)$character";
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
        detect_files = containerFiles;
        symbol = "📦";
        format = "[$symbol$context]($style) ";
        style = "blue bold";
        only_with_files = true;
      };
      custom.podman_context = {
        detect_files = containerFiles;
        when = ''
          command -v podman >/dev/null 2>&1 &&
            (${containerFileTest}) &&
            (! command -v docker >/dev/null 2>&1 || docker --version 2>/dev/null | grep -qi '^podman version')
        '';
        command = ''
          if [[ "$(uname -s)" == "Linux" ]]; then
            socket="''${DOCKER_HOST#unix://}"
            if [[ "$socket" == "''${DOCKER_HOST:-}" ]]; then
              socket=""
            fi

            if [[ -z "$socket" ]]; then
              if [[ -n "''${XDG_RUNTIME_DIR:-}" ]] && [[ -S "''${XDG_RUNTIME_DIR}/podman/podman.sock" ]]; then
                socket="''${XDG_RUNTIME_DIR}/podman/podman.sock"
              elif [[ -S "/run/user/$(id -u)/podman/podman.sock" ]]; then
                socket="/run/user/$(id -u)/podman/podman.sock"
              elif [[ -S "/run/podman/podman.sock" ]]; then
                socket="/run/podman/podman.sock"
              fi
            fi

            if [[ "$socket" == /run/user/*/podman/podman.sock ]]; then
              printf 'podman:rootless'
            elif [[ "$socket" == /run/podman/podman.sock ]] || [[ "$(id -u)" == "0" ]]; then
              printf 'podman:rootful'
            elif [[ -n "''${DOCKER_HOST:-}" ]]; then
              printf 'podman:remote'
            else
              printf 'podman:rootless'
            fi
          else
            machine="''${PODMAN_MACHINE:-}"
            if [[ -z "$machine" ]] && [[ "''${DOCKER_HOST:-}" == unix://*/podman-machine-*-api.sock ]]; then
              socket="''${DOCKER_HOST#unix://}"
              socket="''${socket##*/}"
              machine="''${socket%-api.sock}"
            fi
            if [[ -z "$machine" ]] || ! podman machine inspect "$machine" >/dev/null 2>&1; then
              machine="$(podman machine list --format json 2>/dev/null | jq -r '.[] | select(.Running == true) | .Name' | head -n1)"
            fi
            if [[ -z "$machine" ]]; then
              machine="podman-machine-default"
            fi

            if info="$(podman machine inspect "$machine" --format '{{.State}} {{.Rootful}}' 2>/dev/null)"; then
              state="''${info%% *}"
              rootful="''${info##* }"
              if [[ "$state" == "running" ]]; then
                if [[ "$rootful" == "true" ]]; then
                  printf 'podman:rootful'
                else
                  printf 'podman:rootless'
                fi
              else
                printf 'podman:down'
              fi
            else
              printf 'podman:down'
            fi
          fi
        '';
        symbol = "📦";
        format = "[$symbol$output]($style) ";
        style = "blue bold";
      };
    };
  };
}
