{
  config,
  lib,
  pkgs,
  ...
}:
let
  usagebar = pkgs.buildGoModule rec {
    pname = "herdr-agent-usage";
    version = "0.5.24";
    src = pkgs.fetchFromGitHub {
      owner = "senna-lang";
      repo = "herdr-agent-usage";
      rev = "v${version}";
      hash = "sha256-vlVYd7LnFIjekTjJp9I/4Inoo9Jxz4nlfJCN5+kDomU=";
    };
    vendorHash = "sha256-hbuaZ7QTyOb4OwBR9ZsSpzRLHGgC+0ooQ58Tc+bb62Y=";
    subPackages = [ "cmd/usagebar" ];
    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
    ];
    nativeBuildInputs = [ pkgs.jaq ];
    buildInputs = [ pkgs.bash ];
    postInstall = ''
      pluginDir="$out/share/herdr/plugins/usagebar"
      mkdir -p "$pluginDir"
      cp -r bin "$pluginDir/"
      ln -s "$out/bin/usagebar" "$pluginDir/bin/usagebar"
      # Nix owns builds and updates; omit the upstream build and update hooks.
      jaq --from toml --to toml '
        del(.build) |
        .events |= map(select(.command[1] != "bin/run-update-check.sh"))
      ' herdr-plugin.toml > "$pluginDir/herdr-plugin.toml"
      substituteInPlace "$pluginDir/herdr-plugin.toml" \
        --replace-fail '"bash"' '"${lib.getExe pkgs.bash}"'
      patchShebangs "$pluginDir/bin"
    '';
    meta = {
      description = "Context and quota meters for Herdr agents";
      homepage = "https://github.com/senna-lang/herdr-agent-usage";
      license = lib.licenses.mit;
      mainProgram = "usagebar";
    };
  };

  worktrunkPlugin =
    pkgs.runCommand "herdr-worktrunk"
      {
        src = pkgs.fetchFromGitHub {
          owner = "devashish2203";
          repo = "herdr-worktrunk";
          rev = "f9df9ba700b8a4f4d97ddfe3ea3eb345e80b880b";
          hash = "sha256-puZWyvtBt2svov0NIVJTzdfHzm/k1EglbXsTGsm8N7I=";
        };
      }
      ''
        mkdir -p "$out"
        cp "$src"/*.sh "$src"/*.ps1 "$src/herdr-plugin.toml" "$out/"
        # Herdr launches every entrypoint through the manifest's Bash command.
        substituteInPlace "$out/herdr-plugin.toml" \
          --replace-fail '"bash"' '"${lib.getExe pkgs.bash}"' \
          --replace-fail 'exec bash ' 'export PATH=${
            lib.makeBinPath [
              pkgs.bash
              pkgs.coreutils
              pkgs.fzf
              pkgs.gawk
              pkgs.git
              pkgs.gnused
              pkgs.jq
              pkgs.worktrunk
            ]
          }:$PATH; exec ${lib.getExe pkgs.bash} '
      '';

  hookPath = lib.makeBinPath [
    pkgs.python3
    pkgs.coreutils
  ];

  # Use Herdr's packaged integrations with explicit runtime dependencies.
  sessionHook = agent: {
    type = "command";
    command = ''PATH=${hookPath}:"$PATH" ${pkgs.runtimeShell} ${config.programs.herdr.package}/share/herdr/integrations/${agent}/herdr-agent-state.sh session'';
    timeout = 10;
  };
in
{
  home.packages = [ usagebar ];
  home.activation.herdrAgentUsage = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe config.programs.herdr.package} plugin link ${usagebar}/share/herdr/plugins/usagebar
  '';
  home.activation.herdrWorktrunk = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe config.programs.herdr.package} plugin link ${worktrunkPlugin}
  '';

  xdg.configFile."herdr/plugins/config/worktrunk/config.toml".source =
    (pkgs.formats.toml { }).generate "herdr-worktrunk-config.toml"
      {
        open_mode = "workspace";
        picker_placement = "popup";
      };

  xdg.configFile."herdr/plugins/config/usagebar/config.toml".source =
    (pkgs.formats.toml { }).generate "usagebar-config.toml"
      {
        notify = {
          enabled = true;
          remaining_thresholds = [
            20
            10
            5
          ];
        };
        ui = {
          limit_percent = "remaining";
          cache_display = true;
          sidebar_windows = "shortest";
        };
      };

  programs.herdr = {
    enable = true;
    # Keep Herdr settings declarative, including removal of obsolete values.
    mutableSettings = false;
    settings = {
      onboarding = false;
      # Nix owns binary updates; keep agent-detection manifest updates enabled.
      update.version_check = false;
      terminal.default_shell = lib.getExe pkgs.zsh;
      # Start fresh sessions in Herdr's launch directory; "follow" falls back to $HOME.
      terminal.new_cwd = "current";
      keys = {
        next_agent = "prefix+alt+j";
        previous_agent = "prefix+alt+k";
        focus_agent = "prefix+alt+1..9";
        last_pane = "prefix+backtick";
        # Use Worktrunk's picker for both creating and opening checkouts.
        new_worktree = "";
        open_worktree = "";
        command = [
          {
            key = "prefix+shift+g";
            type = "plugin_action";
            command = "worktrunk.open";
            description = "Worktrunk: switch or create worktree";
          }
          {
            key = "prefix+a";
            type = "pane";
            command = lib.getExe config.programs.codex.package;
            description = "Start Codex";
          }
          {
            key = "prefix+shift+a";
            type = "pane";
            command = "${lib.getExe config.programs.codex.package} resume --all";
            description = "Resume Codex";
          }
          {
            key = "prefix+t";
            type = "popup";
            command = "exec ${lib.getExe pkgs.zsh}";
            description = "Open scratch shell";
            width = "90%";
            height = "90%";
          }
          {
            key = "prefix+alt+g";
            type = "popup";
            command = lib.getExe pkgs.lazygit;
            description = "Open lazygit";
            width = "90%";
            height = "90%";
          }
          {
            key = "prefix+u";
            type = "plugin_action";
            command = "usagebar.open-limits";
            description = "Open agent usage";
          }
          {
            key = "prefix+alt+u";
            type = "plugin_action";
            command = "usagebar.refresh";
            description = "Refresh agent usage";
          }
        ];
      };
      ui = {
        agent_panel_sort = "priority";
        status_indicators = "symbols";
        prompt_new_tab_name = false;
        show_agent_labels_on_pane_borders = true;
        hide_tab_bar_when_single_tab = true;
        sidebar.agents.rows = [
          [
            "state_icon"
            "agent"
            "workspace"
          ]
          [
            "$limit_high"
            {
              token = "$limit_mid";
              fg = "#e0af68";
            }
            {
              token = "$limit_low";
              fg = "#f7768e";
            }
            "$context"
          ]
        ];
        toast = {
          delivery = "terminal";
          delay_seconds = 2;
        };
        sound.enabled = false;
      };
      session.resume_agents_on_restore = true;
      experimental.pane_history = true;
    };
  };

  programs.codex = {
    # Preserve settings written by Codex and its existing plugins.
    mutableSettings = true;
    settings.features.hooks = true;
    hooks.SessionStart = [ { hooks = [ (sessionHook "codex") ]; } ];
  };

  programs.claude-code = {
    enable = true;
    # Manage the integration without changing how Claude itself is installed.
    package = null;
    mutableSettings = true;
    settings.statusLine = {
      type = "command";
      command = "${lib.getExe usagebar} statusline";
    };
    settings.hooks.SessionStart = [
      {
        matcher = "^(startup|resume|clear|compact|fork)$";
        hooks = [ (sessionHook "claude") ];
      }
    ];
  };
}
