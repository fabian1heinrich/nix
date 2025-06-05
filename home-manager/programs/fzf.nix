{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    changeDirWidgetOptions = [
      "--walker-skip .git,node_modules,target"
      "--preview 'tree -C {}'"
    ];
    fileWidgetOptions = [
      "--walker-skip .git,node_modules,target"
      "--preview 'bat -n --color=always {}'"
      "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
      "--bind 'shift-up:preview-page-up,shift-down:preview-page-down'"
      "--height=100%"
    ];
    historyWidgetOptions = [
      "--preview 'echo {}'"
      "--preview-window up:3:hidden:wrap"
      "--bind 'ctrl-/:toggle-preview'"
      "--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"
      "--color header:italic"
      "--header 'Press CTRL-Y to copy command into clipboard'"
    ];
    defaultOptions = [
      "--border"
      "--info=inline"
    ];
  };
}
