#!/usr/bin/env bash
set -u -o pipefail

image="${PODMAN_TEST_IMAGE:-docker.io/library/alpine:3.20}"
podman_bin="$(command -v podman || true)"
failures=0

original_user_cmd=()
rootless_podman_cmd=()
if [[ ${EUID:-$(id -u)} -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  original_uid="$(id -u "$SUDO_USER")"
  original_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  original_user_cmd=(sudo -u "$SUDO_USER" env HOME="$original_home" XDG_RUNTIME_DIR="/run/user/$original_uid" PATH="$PATH")
fi

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  if [[ ${#original_user_cmd[@]} -gt 0 ]]; then
    rootless_podman_cmd=("${original_user_cmd[@]}" "$podman_bin")
  fi
else
  rootless_podman_cmd=("$podman_bin")
fi

section() {
  printf '\n== %s ==\n' "$1"
}

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

skip() {
  printf 'SKIP %s\n' "$1"
}

run_check() {
  local name="$1"
  shift
  local output status

  section "$name"
  output="$("$@" 2>&1)"
  status=$?
  printf '%s\n' "$output"

  if [[ $status -eq 0 ]]; then
    pass "$name"
  else
    fail "$name exited with $status"
  fi
}

podman_mode_check() {
  local name="$1"
  local expected_rootless="$2"
  shift 2
  local podman_cmd=("$@")
  local output status

  section "$name"
  output="$(
    "${podman_cmd[@]}" run --rm --pull=missing "$image" sh -c 'id -u; echo container-run-ok' &&
      "${podman_cmd[@]}" info --format 'rootless: {{.Host.Security.Rootless}}'
  2>&1)"
  status=$?
  printf '%s\n' "$output"

  if [[ $status -eq 0 && "$output" == *"container-run-ok"* && "$output" == *"rootless: $expected_rootless"* ]]; then
    pass "$name"
  else
    fail "$name should run a container and report rootless: $expected_rootless"
  fi
}

check_rootless_container() {
  if [[ ${#rootless_podman_cmd[@]} -eq 0 ]]; then
    section "rootless container"
    printf 'Running as root without SUDO_USER; no original non-root user is available for rootless Podman.\n'
    fail "rootless container requires a non-root user"
    return
  fi

  podman_mode_check "rootless container" "true" "${rootless_podman_cmd[@]}"
}

check_rootful_container() {
  local podman_cmd

  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    podman_cmd=("$podman_bin")
  elif sudo -n true >/dev/null 2>&1; then
    podman_cmd=(sudo -n "$podman_bin")
  else
    section "rootful container"
    printf 'Passwordless sudo is unavailable, so rootful Podman cannot be exercised by this run.\n'
    if [[ "${REQUIRE_ROOTFUL:-0}" == "1" ]]; then
      fail "rootful container requires root or passwordless sudo"
    else
      skip "rootful container"
    fi
    return
  fi

  podman_mode_check "rootful container" "false" "${podman_cmd[@]}"
}

check_user_socket() {
  local systemctl_cmd output status

  section "rootless podman.socket"
  if [[ ${EUID:-$(id -u)} -eq 0 && ${#original_user_cmd[@]} -gt 0 ]]; then
    systemctl_cmd=("${original_user_cmd[@]}" systemctl --user)
  else
    systemctl_cmd=(systemctl --user)
  fi

  output="$("${systemctl_cmd[@]}" is-active podman.socket 2>&1)"
  status=$?
  printf '%s\n' "$output"

  if [[ $status -eq 0 ]]; then
    pass "rootless podman.socket active"
  elif [[ "$output" == "inactive" ]]; then
    pass "rootless podman.socket inactive"
  elif [[ "$output" == *"Unit podman.socket could not be found"* || "$output" == *"Unit podman.socket not found"* ]]; then
    skip "rootless podman.socket unit is not installed"
  elif [[ "$output" == *"Failed to connect to bus"* ]]; then
    skip "rootless podman.socket unavailable without a user systemd bus"
  else
    fail "rootless podman.socket state check exited with $status"
  fi
}

check_machine_list() {
  if [[ ${#rootless_podman_cmd[@]} -eq 0 ]]; then
    section "podman machine list"
    skip "podman machine list requires a non-root user"
    return
  fi

  run_check "podman machine list" "${rootless_podman_cmd[@]}" machine list
}

if [[ "$(uname -s)" != "Linux" ]]; then
  printf 'This test is intended for the Ubuntu/Linux Podman environment.\n' >&2
  exit 2
fi

for required in podman systemctl getent sudo; do
  if ! command -v "$required" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$required" >&2
    exit 2
  fi
done

section "tool versions"
podman --version

check_rootless_container
check_rootful_container
run_check "rootless podman info" "${rootless_podman_cmd[@]}" info
check_machine_list
check_user_socket

if [[ $failures -eq 0 ]]; then
  printf '\nAll Podman capability checks passed.\n'
else
  printf '\n%d Podman capability check(s) failed.\n' "$failures" >&2
  exit 1
fi
