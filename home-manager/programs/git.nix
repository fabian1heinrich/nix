{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "fabianheinrich@aol.com";
        name = "Fabian Heinrich";
      };
      init = {
        defaultBranch = "main";
      };
      credential = {
        "https://github.com" = {
          helper = "!/usr/bin/gh auth git-credential";
        };
        "https://gist.github.com" = {
          helper = "!/usr/bin/gh auth git-credential";
        };
      };
    };
  };
}
