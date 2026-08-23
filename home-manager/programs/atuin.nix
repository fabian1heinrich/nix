{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  # Let Atuin own Ctrl-R while keeping fzf's file and directory widgets.
  programs.fzf.historyWidget.command = "";
}
