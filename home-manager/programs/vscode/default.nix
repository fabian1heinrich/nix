{ config, pkgs, ... }:
let
  extensionSet = pkgs.nix-vscode-extensions.forVSCodeVersion pkgs.vscode.version;
  marketplaceExtensions = extensionSet.vscode-marketplace-release;
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.vscode;
    profiles.default = {
      extensions =
        # Prefer extensions packaged alongside VS Code in nixpkgs.
        (with pkgs.vscode-extensions; [
          aaron-bond.better-comments
          adpyke.codesnap
          alefragnani.bookmarks
          alefragnani.project-manager
          anthropic.claude-code
          bierner.docs-view
          christian-kohler.path-intellisense
          davidanson.vscode-markdownlint
          esbenp.prettier-vscode
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
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode.remote-explorer
          nefrob.vscode-just-syntax
          redhat.vscode-yaml
          stkb.rewrap
          tamasfe.even-better-toml
          timonwong.shellcheck
          usernamehw.errorlens
          vscode-icons-team.vscode-icons
          yzhang.markdown-all-in-one
        ])
        # These extensions are absent from nixpkgs;
        ++ (with marketplaceExtensions; [
          exiasr.hadolint
          ms-vscode.remote-server
          openai.chatgpt
          opentofu.vscode-opentofu
          pomdtr.excalidraw-editor
          zh9528.file-size
        ]);

      enableExtensionUpdateCheck = false;
      userSettings = builtins.fromJSON (builtins.readFile ./settings.json) // {
        "todo-tree.ripgrep.ripgrep" = "${config.home.profileDirectory}/bin/rg";
      };
    };
  };
}
