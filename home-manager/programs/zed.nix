{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkZedContextServer =
    server:
    lib.filterAttrs (_: value: value != null && value != { } && value != [ ]) {
      inherit (server)
        command
        args
        env
        headers
        url
        enabled
        ;
    };
in
{
  programs.zed-editor = {
    enable = true;

    # Zed is installed as a Homebrew cask on macOS; Home Manager owns config.
    package = if pkgs.stdenv.isDarwin then null else pkgs.zed-editor;

    mutableUserSettings = false;
    mutableUserKeymaps = false;
    mutableUserTasks = false;
    mutableUserDebug = false;

    extensions = [
      "nix"
      "vscode-icons"
    ];

    enableMcpIntegration = true;

    userSettings = {
      agent = {
        commit_message_instructions = "Use the Conventional Commits format: <type>(<scope>): <description>.";
        commit_message_model = {
          effort = "high";
          enable_thinking = true;
          model = "gpt-5.5";
          provider = "openai-subscribed";
        };
        dock = "right";
        favorite_models = [ ];
        flexible = true;
        model_parameters = [ ];
        sidebar_side = "right";
      };
      agent_servers = {
        codex-acp = {
          default_config_options = {
            mode = "full-access";
            reasoning_effort = "high";
          };
          type = "registry";
        };
      };
      context_servers = lib.mapAttrs (_: mkZedContextServer) config.programs.mcp.servers;
      auto_indent_on_paste = true;
      autosave = "on_focus_change";
      base_keymap = "VSCode";
      buffer_font_family = "MesloLGL Nerd Font";
      buffer_font_fallbacks = [ "monospace" ];
      buffer_font_size = 15;
      collaboration_panel = {
        button = false;
      };
      debugger = {
        button = false;
      };
      features = {
        copilot = false;
      };
      format_on_save = "on";
      git_panel = {
        dock = "left";
        tree_view = true;
      };
      gutter = {
        folds = true;
      };
      icon_theme = {
        dark = "VSCode Icons for Zed (Dark Angular)";
        light = "VSCode Icons for Zed (Light Angular)";
        mode = "dark";
      };
      minimap = {
        show = "never";
      };
      multi_cursor_modifier = "cmd_or_ctrl";
      outline_panel = {
        dock = "left";
      };
      project_panel = {
        bold_folder_labels = true;
        diagnostic_badges = true;
        dock = "left";
        git_status_indicator = true;
        sort_order = "unicode";
      };
      session = {
        trust_all_worktrees = true;
      };
      show_edit_predictions = true;
      soft_wrap = "editor_width";
      terminal = {
        copy_on_select = true;
        env = {
          CW_NEW_SESSION = "1";
        };
        font_fallbacks = [ "monospace" ];
        font_family = "MesloLGS Nerd Font Mono";
        line_height = {
          custom = 1.0;
        };
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      theme = {
        dark = "GitHub Dark Dimmed";
        light = "GitHub Light";
        mode = "dark";
      };
      ui_font_size = 16;
      use_on_type_format = true;
      vim_mode = false;
    };

    userTasks = [
      {
        label = "Nix format";
        command = "just nix-fmt";
        use_new_terminal = false;
      }
    ];
  };
}
