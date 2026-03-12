{
  lib,
  pkgs,
  ...
}:
let
  bwItemIds = {
    BW_ITEM_ID_OPENAI_API_KEY = "6f8ac208-588d-4385-b6e2-b40600f97190";
    BW_ITEM_ID_ANTHROPIC_API_KEY = "16adf109-f1b8-4276-9d44-b40600f99483";
    BW_ITEM_ID_GITHUB_PERSONAL_ACCESS_TOKEN = "134b23e4-ae15-4fe6-947f-b40600f9eb9e";
    BW_ITEM_ID_BRAVE_API_KEY = "78786557-cdd4-4aa1-ace1-b40600f9b65f";
    BW_ITEM_ID_CONTEXT7_API_KEY = "6454db93-71be-4266-ab33-b40600f9d16d";
  };

  bwSyncApiKeys = pkgs.writeShellApplication {
    name = "bw-sync-api-keys";
    runtimeInputs = with pkgs; [
      bitwarden-cli
      jq
      coreutils
    ];
    text = builtins.readFile ../scripts/bw-sync-api-keys.sh;
  };
in
{
  home.packages = [
    bwSyncApiKeys
    pkgs.bitwarden-cli
  ];
  home.sessionVariables = bwItemIds;

  programs.zsh.initContent = lib.mkBefore ''
    if command -v bw-sync-api-keys >/dev/null 2>&1; then
      bw-refresh-api-keys() {
        eval "$(bw-sync-api-keys --export-shell "$@")"
      }

      alias bw-refresh-secrets='bw-refresh-api-keys'

      if [ "''${BW_SYNC_API_KEYS_ON_START:-0}" = "1" ] \
        || [ -z "''${OPENAI_API_KEY:-}" ] \
        || [ -z "''${ANTHROPIC_API_KEY:-}" ] \
        || [ -z "''${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ] \
        || [ -z "''${BRAVE_API_KEY:-}" ] \
        || [ -z "''${CONTEXT7_API_KEY:-}" ]; then
        bw-refresh-api-keys --no-unlock
      fi
    fi
  '';
}
