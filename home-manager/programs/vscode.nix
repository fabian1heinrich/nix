{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        aaron-bond.better-comments
        adpyke.codesnap
        alefragnani.bookmarks
        alefragnani.project-manager
        bierner.docs-view
        christian-kohler.path-intellisense
        davidanson.vscode-markdownlint
        esbenp.prettier-vscode
        foxundermoon.shell-format
        github.github-vscode-theme
        github.vscode-github-actions
        github.vscode-pull-request-github
        gruntfuggly.todo-tree
        jnoortheen.nix-ide
        johnpapa.vscode-peacock
        mads-hartmann.bash-ide-vscode
        ms-azuretools.vscode-containers
        ms-toolsai.jupyter-keymap
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.remote-explorer
        nefrob.vscode-just-syntax
        redhat.vscode-yaml
        tamasfe.even-better-toml
        timonwong.shellcheck
        usernamehw.errorlens
        vscode-icons-team.vscode-icons
        yzhang.markdown-all-in-one
      ];

      enableExtensionUpdateCheck = false;
      userSettings = ./vscode/settings.json;
    };
  };
}
