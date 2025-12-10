{ pkgs, ... }:
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
        helper = "store";
        "https://github.com" = {
          helper = "!${pkgs.gh}/bin/gh auth git-credential";
        };
        "https://gist.github.com" = {
          helper = "!${pkgs.gh}/bin/gh auth git-credential";
        };
      };
    };
  };
}
