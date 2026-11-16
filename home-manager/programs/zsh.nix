{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    history = {
      ignoreAllDups = true;
      ignoreSpace = true;
      save = 1000000;
      size = 1000000;
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "dirhistory"
      ];
    };

    plugins = [
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
    ];
    shellAliases = {
      cat = lib.getExe pkgs.bat;
    };
    initContent = lib.mkMerge [
      # Homebrew completions live outside the Nix profile paths. This must run
      # before compinit, which oh-my-zsh calls at order 800; a plain
      # initContent string is order 1000, far too late for fpath to matter.
      (lib.mkOrder 550 (
        lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
            fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
          fi
        ''
      ))

      ''

        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          export LANG="en_US.UTF-8"
          export LC_CTYPE="en_US.UTF-8"
        ''}

        # One title owner across Ghostty, Herdr, and other terminals.
        DISABLE_AUTO_TITLE=true
        _worktree_terminal_title() {
          emulate -L zsh
          local terminal_title="''${(%):-%~}"
          local repo_name
          local -a git_paths
          if git_paths=("''${(@f)$(command git rev-parse --path-format=absolute --git-dir --git-common-dir --show-toplevel 2>/dev/null)}"); then
            terminal_title="''${git_paths[3]:t}"
            if [[ "''${git_paths[1]}" != "''${git_paths[2]}" ]]; then
              repo_name="''${git_paths[2]:t}"
              [[ "$repo_name" == .git ]] && repo_name="''${git_paths[2]:h:t}"
              terminal_title="''${repo_name%.git} · $terminal_title"
            fi
          fi
          # Paths are literal text, never prompt escapes or terminal controls.
          terminal_title="''${terminal_title//[[:cntrl:]]/}"
          printf '\033]2;%s\007\033]1;%s\007' "$terminal_title" "$terminal_title"
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _worktree_terminal_title

        bindkey "^[[1;3C" forward-word
        bindkey "^[[1;3D" backward-word
        bindkey "^U" backward-kill-line
        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey "^E" edit-command-line

        _select_backward_char() {
          (( REGION_ACTIVE )) || zle set-mark-command
          zle backward-char
        }

        _select_forward_char() {
          (( REGION_ACTIVE )) || zle set-mark-command
          zle forward-char
        }

        _copy_region_to_clipboard() {
          (( REGION_ACTIVE )) || return

          local start=$MARK
          local end=$CURSOR

          if (( start > end )); then
            local tmp=$start
            start=$end
            end=$tmp
          fi

          if (( end == start )); then
            return
          fi

          if command -v pbcopy >/dev/null 2>&1; then
            print -rn -- "''${BUFFER:$start:$(( end - start ))}" | pbcopy
          elif command -v wl-copy >/dev/null 2>&1; then
            print -rn -- "''${BUFFER:$start:$(( end - start ))}" | wl-copy
          elif command -v xclip >/dev/null 2>&1; then
            print -rn -- "''${BUFFER:$start:$(( end - start ))}" | xclip -selection clipboard
          fi
        }

        zle -N _select_backward_char
        zle -N _select_forward_char
        zle -N _copy_region_to_clipboard

        bindkey "^[[1;2D" _select_backward_char
        bindkey "^[[1;2C" _select_forward_char
        bindkey "^[[99;9u" _copy_region_to_clipboard

      ''
    ];
  };
}
