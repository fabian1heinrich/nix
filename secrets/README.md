# Secrets

API keys are loaded from Bitwarden via `bw-sync-api-keys`.
Bitwarden item IDs are configured in `home-manager/programs/bitwarden-secrets.nix`.

On shell startup, a non-blocking sync runs automatically.
Run `bw login` every 8 hours.

Use after changing secrets in the vault:

```bash
bw-refresh-secrets
```

Non-blocking (skip unlock prompt):

```bash
bw-refresh-secrets --no-unlock
```
