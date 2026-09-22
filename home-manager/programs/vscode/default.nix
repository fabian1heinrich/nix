{ config, pkgs, ... }:
let
  extensions =
    (pkgs.nix-vscode-extensions.forVSCodeVersion pkgs.vscode.version).vscode-marketplace-release;
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with extensions; [
        aaron-bond.better-comments
        adpyke.codesnap
        alefragnani.bookmarks
        alefragnani.project-manager
        bierner.docs-view
        christian-kohler.path-intellisense
        davidanson.vscode-markdownlint
        esbenp.prettier-vscode
        exiasr.hadolint
        foxundermoon.shell-format
        github.codespaces
        github.github-vscode-theme
        github.vscode-github-actions
        github.vscode-pull-request-github
        gruntfuggly.todo-tree
        jnoortheen.nix-ide
        johnpapa.vscode-peacock
        mads-hartmann.bash-ide-vscode
        ms-azuretools.vscode-containers
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-python.vscode-python-envs
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.remote-explorer
        ms-vscode.remote-server
        nefrob.vscode-just-syntax
        openai.chatgpt
        opentofu.vscode-opentofu
        pomdtr.excalidraw-editor
        redhat.vscode-yaml
        sst-dev.opencode
        stkb.rewrap
        tamasfe.even-better-toml
        timonwong.shellcheck
        usernamehw.errorlens
        vscode-icons-team.vscode-icons
        yzhang.markdown-all-in-one
        zh9528.file-size
      ];

      enableExtensionUpdateCheck = false;
      userSettings = builtins.fromJSON (builtins.readFile ./settings.json) // {
        "todo-tree.ripgrep.ripgrep" = "${config.home.profileDirectory}/bin/rg";
      };
    };
  };
}
