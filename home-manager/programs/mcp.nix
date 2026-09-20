{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Paths are relative to $HOME.
  linuxMcpJsonTargets = [
    # ".cursor/mcp.json"
    # ".config/windsurf/mcp.json"
  ];

  mcpJsonTargets = lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxMcpJsonTargets;

  # GUI clients may launch MCP servers with a restricted PATH, so use the
  # active Home Manager profile binaries explicitly.
  profileBin = "${config.home.profileDirectory}/bin";
  mcpServers = import ./mcp-servers.nix {
    homeDirectory = config.home.homeDirectory;
    binDirectory = profileBin;
  };
in
{
  home.packages = with pkgs; [
    nodejs
    uv
  ];

  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };

  home.activation.ensureMcpDataDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -d -m 0700 ${lib.escapeShellArg "${config.home.homeDirectory}/.local/share/mcp"}
  '';

  home.file = lib.genAttrs mcpJsonTargets (_: {
    source = config.xdg.configFile."mcp/mcp.json".source;
  });
}
