{
  lib,
  pkgs,
  userConfig,
  ...
}:
let
  # ChatGPT desktop and the other local Codex clients merge this system layer
  # with the mutable user configuration under ~/.codex.
  systemBin = "/run/current-system/sw/bin";
  mcpServers = import ../../home-manager/programs/mcp-servers.nix {
    homeDirectory = userConfig.homeDirectory;
    binDirectory = systemBin;
  };
  codexMcpServers = lib.mapAttrs (
    _: server:
    server
    // {
      # Read-only tools can run directly; mutating tools require confirmation.
      default_tools_approval_mode = "writes";
    }
  ) mcpServers;
  toml = pkgs.formats.toml { };
in
{
  environment = {
    systemPackages = with pkgs; [
      nodejs
      uv
    ];

    etc."codex/config.toml".source = toml.generate "codex-system-config.toml" {
      mcp_servers = codexMcpServers;
    };
  };

  system.activationScripts.mcpDataDirectory.text = ''
    install -d -m 0700 \
      -o ${lib.escapeShellArg userConfig.username} \
      -g staff \
      ${lib.escapeShellArg "${userConfig.homeDirectory}/.local/share/mcp"}
  '';
}
