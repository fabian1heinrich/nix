{
  programs.lsd = {
    enable = true;
    enableAliases = true;
    settings = {
      classic = false;
      date = "date";
      blocks = [
        "permission"
        "user"
        "group"
        "size"
        "date"
        "name"
      ];
    };
    icons = {
      name = {
        ".gitignore" = "🌱";
        ".git" = "🌱";
        "dockerfile" = "🐳";
        "docker-compose.yml" = "🐳";
        ".ds_store" = "🍏";
        "pyproject.toml" = "🐍";
        ".cache" = "♻️";
      };
      extension = {
        go = "";
        rs = "🦀";
        py = "🐍";
        sh = "🚀";
        zsh = "🚀";
        lock = "🔒";
        toml = "🍅";
        md = "📝";
      };
      filetype = {
        dir = "📂";
        file = "📄";
        pipe = "📩";
        executable = "🚀";
      };
    };
  };
}
