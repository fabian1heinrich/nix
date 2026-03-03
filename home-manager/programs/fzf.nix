{ lib, pkgs, ... }:
let
  clipboardCopyScript =
    if pkgs.stdenv.isLinux then
      pkgs.writeShellScript "fzf-copy-to-clipboard" ''
        if [ -n "$WAYLAND_DISPLAY" ]; then
          exec ${pkgs.wl-clipboard}/bin/wl-copy
        elif [ -n "$DISPLAY" ]; then
          exec ${pkgs.xclip}/bin/xclip -selection clipboard
        else
          exec ${pkgs.wl-clipboard}/bin/wl-copy
        fi
      ''
    else
      null;

  clipboardCopyCommand =
    if pkgs.stdenv.isDarwin then
      "pbcopy"
    else if pkgs.stdenv.isLinux then
      "${clipboardCopyScript}"
    else
      null;
in
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
    historyWidgetOptions =
      [
        "--preview 'echo {}'"
        "--preview-window up:3:hidden:wrap"
        "--bind 'ctrl-/:toggle-preview'"
        "--color header:italic"
      ]
      ++ lib.optionals (clipboardCopyCommand != null) [
        "--bind 'ctrl-y:execute-silent(echo -n {2..} | ${clipboardCopyCommand})+abort'"
        "--header 'Press CTRL-Y to copy command into clipboard'"
      ]
      ++ lib.optionals (clipboardCopyCommand == null) [
        "--header 'Clipboard copy binding unavailable on this platform'"
      ];
    defaultOptions = [
      "--border"
      "--info=inline"
    ];
  };
}
