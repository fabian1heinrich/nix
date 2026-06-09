{
  config,
  lib,
  pkgs,
  ...
}:
let
  bwSyncApiKeys = pkgs.writeShellApplication {
    name = "bw-sync-api-keys";
    runtimeInputs = with pkgs; [
      bitwarden-cli
      jq
      coreutils
    ];
    text = builtins.readFile ../scripts/bw-sync-api-keys.sh;
  };

  itemRefsPath = "${config.xdg.configHome}/bw-api-key-items.env";
  defaultItemRefs = ''
    # Created once by Home Manager. Edit this file if your Bitwarden item names
    # differ, or replace values with item IDs for stable lookup.
    BW_ITEM_REF_OPENAI_API_KEY=OPENAI_API_KEY
    BW_ITEM_REF_ANTHROPIC_API_KEY=ANTHROPIC_API_KEY
    BW_ITEM_REF_GITHUB_PERSONAL_ACCESS_TOKEN=GITHUB_PERSONAL_ACCESS_TOKEN
    BW_ITEM_REF_BRAVE_API_KEY=BRAVE_API_KEY
    BW_ITEM_REF_CONTEXT7_API_KEY=CONTEXT7_API_KEY
  '';
  defaultItemRefsFile = pkgs.writeText "bw-api-key-items.env.default" defaultItemRefs;
in
{
  home.packages = [
    bwSyncApiKeys
    pkgs.bitwarden-cli
  ];

  xdg.configFile."bw-api-key-items.env.example".text = defaultItemRefs;

  home.activation.ensureBwApiKeyItemRefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target=${lib.escapeShellArg itemRefsPath}
    if [ ! -e "$target" ]; then
      install -d -m 0700 ${lib.escapeShellArg config.xdg.configHome}
      install -m 0600 ${lib.escapeShellArg defaultItemRefsFile} "$target"
    fi
  '';

  programs.zsh.initContent = lib.mkBefore ''
    if command -v bw-sync-api-keys >/dev/null 2>&1; then
      bw-refresh-api-keys() {
        local exports
        exports="$(bw-sync-api-keys --export-shell "$@")" || return
        eval "$exports"
      }

      alias bw-refresh-secrets='bw-refresh-api-keys'

      if [ "''${BW_SYNC_API_KEYS_ON_START:-0}" = "1" ]; then
        bw-refresh-api-keys --no-unlock --quiet
      fi
    fi
  '';
}
