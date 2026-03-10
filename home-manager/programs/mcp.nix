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

  darwinMcpJsonTargets = [
    "Library/Application Support/Claude/claude_desktop_config.json"
  ];

  mcpJsonTargets =
    (lib.optionals pkgs.stdenv.isLinux linuxMcpJsonTargets)
    ++ (lib.optionals pkgs.stdenv.isDarwin darwinMcpJsonTargets);
in
{
  programs.mcp = {
    enable = true;
    servers = {
      everything = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
    };
  };

  home.file = lib.genAttrs mcpJsonTargets (_: {
    source = config.xdg.configFile."mcp/mcp.json".source;
  });
}
