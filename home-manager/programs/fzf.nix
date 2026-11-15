{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.fzf;
  clipboardCopyScript =
    if pkgs.stdenv.hostPlatform.isLinux then
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
    if pkgs.stdenv.hostPlatform.isDarwin then
      "pbcopy"
    else if pkgs.stdenv.hostPlatform.isLinux then
      "${clipboardCopyScript}"
    else
      null;
in
{
  home.packages = lib.mkIf cfg.enable (
    with pkgs;
    [
      bat
      dnsutils
      fd
      tree
    ]
  );

  programs.zsh = lib.mkIf (cfg.enable && cfg.enableZshIntegration) {
    # fzf-tab must load before plugins that wrap ZLE widgets.
    plugins = lib.mkBefore [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    initContent = ''
      export FZF_COMPLETION_TRIGGER='~~'

      _fzf_compgen_path() {
        fd --hidden --follow --exclude ".git" . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude ".git" . "$1"
      }

      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
        cd) fzf --preview 'tree -C {} | head -200' "$@" ;;
        export | unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
        ssh) fzf --preview 'dig {}' "$@" ;;
        *) fzf --preview 'bat -n --color=always {}' "$@" ;;
        esac
      }

      bindkey "ç" fzf-cd-widget
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    changeDirWidget.options = [
      "--walker-skip .git,node_modules,target"
      "--preview 'tree -C {}'"
    ];
    fileWidget.options = [
      "--walker-skip .git,node_modules,target"
      "--preview 'bat -n --color=always {}'"
      "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
      "--bind 'shift-up:preview-page-up,shift-down:preview-page-down'"
      "--height=100%"
    ];
    historyWidget.options = [
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
