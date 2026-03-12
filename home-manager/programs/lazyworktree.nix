{
  programs.lazyworktree = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "lwt";
    settings = {
      icon_set = "nerd-font-v3";
      palette_mru = true;
      palette_mru_limit = 5;
      sort_mode = "switched";
    };
  };
}
