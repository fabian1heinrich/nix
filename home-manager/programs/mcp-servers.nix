{
  homeDirectory,
  binDirectory,
}:
let
  mcpPath = builtins.concatStringsSep ":" [
    binDirectory
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

  mkLocalServer =
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
  filesystem = mkLocalServer {
    command = "${binDirectory}/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      homeDirectory
    ];
  };

  memory = mkLocalServer {
    command = "${binDirectory}/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-memory"
    ];
    env = {
      MEMORY_FILE_PATH = "${homeDirectory}/.local/share/mcp/memory.jsonl";
    };
  };

  fetch = mkLocalServer {
    command = "${binDirectory}/uvx";
    args = [ "mcp-server-fetch" ];
  };

  brave-search = mkLocalServer {
    command = "${binDirectory}/npx";
    args = [
      "-y"
      "@brave/brave-search-mcp-server"
      "--transport"
      "stdio"
    ];
    # Forward the key from the client process without writing it to generated
    # MCP configuration.
    env_vars = [ "BRAVE_API_KEY" ];
  };

  sequential-thinking = mkLocalServer {
    command = "${binDirectory}/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sequential-thinking"
    ];
  };

  context7 = {
    # The remote endpoint supports anonymous use and optional OAuth in clients
    # such as the ChatGPT desktop app.
    url = "https://mcp.context7.com/mcp";
  };
}
