{
  programs.codex = {
    enable = true;
    # The ChatGPT desktop app mutates ~/.codex/config.toml for plugins, trust,
    # hooks, and desktop settings. Keep that file outside Home Manager; the
    # legendre host supplies shared MCP defaults through /etc/codex/config.toml.
    enableMcpIntegration = false;
  };
}
