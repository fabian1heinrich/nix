#!/usr/bin/env bash

set -euo pipefail

script=${1:?usage: bw-sync-api-keys-test.sh PATH_TO_SCRIPT}
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/home"

cat >"$test_root/bin/bw" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-} ${2:-}" in
  "login --check" | "list items")
    exit 0
    ;;
  "get item")
    item_ref=${3:?missing item ref}
    if [ "$item_ref" = "${BW_TEST_MISSING_REF:-}" ]; then
      exit 1
    fi
    if [ "$item_ref" = "OPENAI_API_KEY" ]; then
      printf '%s\n' '{"login":{"password":"value-with-a-single-quote'"'"'"}}'
    else
      printf '{"login":{"password":"value-%s"}}\n' "$item_ref"
    fi
    ;;
  *)
    printf 'unexpected bw invocation: %s\n' "$*" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$test_root/bin/bw"

export HOME="$test_root/home"
export PATH="$test_root/bin:$PATH"
export BW_ITEM_REF_OPENAI_API_KEY="OPENAI_API_KEY"
export BW_ITEM_REF_ANTHROPIC_API_KEY="ANTHROPIC_API_KEY"
export BW_ITEM_REF_GITHUB_PERSONAL_ACCESS_TOKEN="GITHUB_PERSONAL_ACCESS_TOKEN"
export BW_ITEM_REF_BRAVE_API_KEY="BRAVE_API_KEY"
export BW_ITEM_REF_CONTEXT7_API_KEY="CONTEXT7_API_KEY"

run_sync() (
  export BW_SESSION="test-session"
  bash "$script" --export-shell --quiet
)

output=$(run_sync)

if grep -q 'BW_SESSION' <<<"$output"; then
  printf 'BW_SESSION must not be exported\n' >&2
  exit 1
fi

# The output is deliberately shell code consumed by the interactive wrapper.
# shellcheck disable=SC2294
eval "$output"

[ "$OPENAI_API_KEY" = "value-with-a-single-quote'" ]
[ "$ANTHROPIC_API_KEY" = "value-ANTHROPIC_API_KEY" ]
[ "$GITHUB_PERSONAL_ACCESS_TOKEN" = "value-GITHUB_PERSONAL_ACCESS_TOKEN" ]
[ "$BRAVE_API_KEY" = "value-BRAVE_API_KEY" ]
[ "$CONTEXT7_API_KEY" = "value-CONTEXT7_API_KEY" ]

missing_output="$test_root/missing-output"
if BW_TEST_MISSING_REF=CONTEXT7_API_KEY run_sync >"$missing_output" 2>/dev/null; then
  printf 'partial secret refresh unexpectedly succeeded\n' >&2
  exit 1
fi

if [ -s "$missing_output" ]; then
  printf 'partial secret refresh emitted incomplete exports\n' >&2
  exit 1
fi

locked_output="$test_root/locked-output"
if (
  unset BW_SESSION
  bash "$script" --export-shell --no-unlock --quiet
) >"$locked_output" 2>/dev/null; then
  printf 'locked non-interactive refresh unexpectedly succeeded\n' >&2
  exit 1
fi

if [ -s "$locked_output" ]; then
  printf 'locked refresh emitted exports\n' >&2
  exit 1
fi
