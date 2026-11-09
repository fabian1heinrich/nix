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
  home.activation.herdrAgentUsage = lib.hm.dag.entryAfter [ "herdrMutableSettings" ] ''
    run ${lib.getExe config.programs.herdr.package} plugin link ${usagebar}/share/herdr/plugins/usagebar
  '';

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
    mutableSettings = true;
    settings = {
      onboarding = false;
      # Nix owns binary updates; keep agent-detection manifest updates enabled.
      update.version_check = false;
      terminal.default_shell = lib.getExe pkgs.zsh;
      keys = {
        next_agent = "prefix+alt+j";
        previous_agent = "prefix+alt+k";
        focus_agent = "prefix+alt+1..9";
        # Create checkouts with Worktrunk; open them in Herdr afterwards.
        new_worktree = "";
        open_worktree = "prefix+shift+g";
        command = [
          {
            key = "prefix+a";
            type = "pane";
            command = lib.getExe config.programs.codex.package;
            description = "Start Codex";
          }
          {
            key = "prefix+alt+g";
            type = "pane";
            command = lib.getExe pkgs.lazygit;
            description = "Open lazygit";
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
        sidebar.agents.rows = [
          [
            "state_icon"
            "agent"
            "state_text"
          ]
          [
            "machine"
            "workspace"
            "tab"
            "pane"
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
          [
            "$cache_high"
            {
              token = "$cache_mid";
              fg = "#e0af68";
            }
            {
              token = "$cache_low";
              fg = "#f7768e";
            }
          ]
        ];
        toast = {
          delivery = "terminal";
          delay_seconds = 2;
        };
        sound.enabled = false;
      };
      session.resume_agents_on_restore = true;
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
