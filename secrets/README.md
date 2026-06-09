# Secrets

API keys are loaded from Bitwarden via `bw-sync-api-keys`.
Bitwarden item references are configured at runtime, outside this repository.

Home Manager creates `~/.config/bw-api-key-items.env` on first activation if it
does not already exist. By default it expects Bitwarden items named after the
exported environment variables:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GITHUB_PERSONAL_ACCESS_TOKEN`
- `BRAVE_API_KEY`
- `CONTEXT7_API_KEY`

If your vault uses different item names, edit `~/.config/bw-api-key-items.env`
and set each value to either the exact Bitwarden item name or the item ID.
Home Manager will not overwrite an existing file.

Run `bw login` every 8 hours.

Use after changing secrets in the vault:

```bash
bw-refresh-secrets
```

Non-blocking (skip unlock prompt):

```bash
bw-refresh-secrets --no-unlock
```

Shell startup does not query Bitwarden by default. To enable a quiet startup
sync when the vault is already unlocked:

```bash
export BW_SYNC_API_KEYS_ON_START=1
```
