{ ... }:
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
      };
    };
  };
}
