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

  # Claude Desktop may launch MCP servers with a restricted PATH.
  # Use the active Home Manager profile binaries explicitly.
  profileBin = "${config.home.profileDirectory}/bin";
  npx = "${profileBin}/npx";
  uvx = "${profileBin}/uvx";
  mcpPath = lib.concatStringsSep ":" [
    profileBin
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
  mkServer =
    server:
    server
    // {
      env = {
        PATH = mcpPath;
      }
      // (server.env or { });
    };
in
{
  programs.mcp = {
    enable = true;
    servers = {
      filesystem = mkServer {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          config.home.homeDirectory
        ];
      };

      memory = mkServer {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-memory"
        ];
        env = {
          MEMORY_FILE_PATH = "${config.home.homeDirectory}/.local/share/mcp/memory.jsonl";
        };
      };

      fetch = mkServer {
        command = uvx;
        args = [ "mcp-server-fetch" ];
      };

      brave-search = mkServer {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-brave-search"
        ];
        env = {
          BRAVE_API_KEY = "{env:BRAVE_API_KEY}";
        };
      };

      sequential-thinking = mkServer {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };

      context7 = mkServer {
        command = npx;
        args = [
          "-y"
          "@upstash/context7-mcp"
          "--api-key"
          "{env:CONTEXT7_API_KEY}"
        ];
      };
    };
  };

  home.file = lib.genAttrs mcpJsonTargets (_: {
    source = config.xdg.configFile."mcp/mcp.json".source;
  });
}
