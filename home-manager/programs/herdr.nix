{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  programs.herdr = {
    enable = true;
    mutableSettings = true;
    settings = {
      onboarding = false;
      # Nix owns binary updates; keep agent-detection manifest updates enabled.
      update.version_check = false;
      terminal.default_shell = lib.getExe pkgs.zsh;
      ui = {
        agent_panel_sort = "priority";
        toast.delivery = "terminal";
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
    settings.hooks.SessionStart = [
      {
        matcher = "^(startup|resume|clear|compact|fork)$";
        hooks = [ (sessionHook "claude") ];
      }
    ];
  };
}
