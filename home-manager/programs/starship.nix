{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$username$hostname( $kubernetes)( $directory)( $docker_context)( $python)($git_branch) ";
      username = {
        format = "[$user]($style)[@]($style)";
        disabled = false;
        show_always = true;
        style_user = "bold green";
      };
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol]($style)[$hostname]($style)";
        disabled = false;
        ssh_symbol = "🌍";
        trim_at = ".";
        style = "bold green";
      };
      git_branch = {
        symbol = "🌱";
        truncation_length = 20;
        truncation_symbol = "";
        format = "[$symbol$branch(:$remote_branch)]($style)";
      };
      python = {
        symbol = "🐍";
        style = "yellow bold";
        format = "[$symbol $version ($virtualenv)]($style)";
        version_format = "v$major.$minor";
      };
      kubernetes = {
        symbol = "🪐";
        disabled = false;
        format = ''[$symbol$context \($namespace\)]($style)'';
        detect_env_vars = [ "KUBECONFIG" ];
      };
    };
  };
}
