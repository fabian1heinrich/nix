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
      filesystem = {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          userConfig.homeDirectory
        ];
      };

      memory = {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-memory"
        ];
        env = {
          MEMORY_FILE_PATH = "${userConfig.homeDirectory}/.local/share/mcp/memory.jsonl";
        };
      };

      fetch = {
        command = uvx;
        args = [ "mcp-server-fetch" ];
      };

      github = {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-github"
        ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "{env:GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };

      brave-search = {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-brave-search"
        ];
        env = {
          BRAVE_API_KEY = "{env:BRAVE_API_KEY}";
        };
      };

      sequential-thinking = {
        command = npx;
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };

      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
    };
  };

  home.file = lib.genAttrs mcpJsonTargets (_: {
    source = config.xdg.configFile."mcp/mcp.json".source;
  });
}
