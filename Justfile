set shell := ["bash", "-uc"]

os := `uname -s`
cluster := env("KIND_CLUSTER", "dev")
docker := "env -u DOCKER_HOST -u CONTAINER_HOST -u CONTAINER_CONNECTION -u DOCKER_CONTEXT docker"

default:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" --list

nix-check:
    nix flake check --all-systems --no-build

nix-shellcheck:
    nix build .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).shellcheck

nix-fmt:
    nix fmt

nix-update:
    nix flake update

switch-legendre:
    sudo darwin-rebuild switch --flake .#legendre

switch-ubuntu-dev:
    home-manager switch --flake .#ubuntu-dev

build-euler-vm-iso:
    @iso_root="$(nix build .#euler-vm-installer-iso --no-link --print-out-paths)"; \
      find "$iso_root/iso" -maxdepth 1 -type f -name '*.iso' -print -quit

build-euler-baremetal-iso:
    @iso_root="$(nix build .#euler-baremetal-installer-iso --no-link --print-out-paths)"; \
      find "$iso_root/iso" -maxdepth 1 -type f -name '*.iso' -print -quit

build-euler-iso:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" build-euler-baremetal-iso

list-usb-drives:
    @case "{{ os }}" in \
      Linux) ;; \
      *) echo "USB drive discovery is only supported on Linux for now. Current OS: {{ os }}" >&2; exit 1 ;; \
    esac
    @found=0; \
      printf '%-12s %-16s %-8s %-6s %s\n' NAME PATH SIZE TRAN MODEL; \
      while IFS= read -r device; do \
        path="$(lsblk --nodeps --noheadings --output PATH "$device" | tr -d '[:space:]')"; \
        size="$(lsblk --nodeps --noheadings --output SIZE "$device" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"; \
        tran="$(lsblk --nodeps --noheadings --output TRAN "$device" | tr -d '[:space:]')"; \
        model="$(lsblk --nodeps --noheadings --output MODEL "$device" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"; \
        printf '%-12s %-16s %-8s %-6s %s\n' "$(basename "$device")" "$path" "$size" "$tran" "$model"; \
        found=1; \
      done < <(lsblk --nodeps --paths --noheadings --output PATH,TYPE,RM,TRAN | awk '$2 == "disk" && ($3 == "1" || $4 == "usb") { print $1 }'); \
      if [ "$found" -eq 0 ]; then \
        echo "No portable USB/removable drives detected."; \
      fi
    @echo
    @echo "Use the PATH for the whole disk, for example /dev/sdb."
    @echo "Do not use a partition path such as /dev/sdb1."

write-euler-iso-usb $device:
    @case "{{ os }}" in \
      Linux) ;; \
      *) echo "USB writing is only supported on x86_64-linux for now. Current OS: {{ os }}" >&2; exit 1 ;; \
    esac
    @system="$(nix eval --raw --impure --expr builtins.currentSystem)"; \
      if [ "$system" != "x86_64-linux" ]; then \
        echo "USB writing is only supported on x86_64-linux for now. Current Nix system: $system" >&2; \
        exit 1; \
      fi
    @target="$device"; \
      case "$target" in \
        /dev/*) ;; \
        *) echo "USB target must be a /dev block device, got: $target" >&2; exit 2 ;; \
      esac; \
      if [ ! -b "$target" ]; then \
        echo "Not a block device: $target" >&2; \
        exit 1; \
      fi; \
      device_type="$(lsblk --nodeps --noheadings --output TYPE "$target" | tr -d '[:space:]')"; \
      if [ "$device_type" != "disk" ]; then \
        echo "Refusing to write to a partition or non-disk device. Use the whole USB disk, for example /dev/sdX or /dev/nvmeXnY." >&2; \
        exit 1; \
      fi; \
      echo "Target USB device:"; \
      lsblk -o NAME,MODEL,SIZE,TRAN,TYPE,MOUNTPOINTS "$target"; \
      echo; \
      echo "This will destroy all data on $target and replace it with the Euler bootable installer ISO."; \
      printf 'Type YES to continue: '; \
      read -r confirmation; \
      if [ "$confirmation" != "YES" ]; then \
        echo "Aborted." >&2; \
        exit 1; \
      fi; \
      iso="$(just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" build-euler-iso)"; \
      if [ ! -f "$iso" ]; then \
        echo "ISO build did not produce a file: $iso" >&2; \
        exit 1; \
      fi; \
      echo "Writing bootable ISO to $target:"; \
      echo "  $iso"; \
      while IFS= read -r mountpoint; do \
        [ -n "$mountpoint" ] || continue; \
        sudo umount "$mountpoint"; \
      done < <(lsblk --noheadings --raw --output MOUNTPOINT "$target" | sed '/^$/d'); \
      sudo dd if="$iso" of="$target" bs=4M status=progress oflag=direct conv=fsync; \
      echo "Flushing USB write cache. This can take several minutes on slow sticks..."; \
      sudo blockdev --flushbufs "$target"; \
      echo "Euler installer USB is ready. Boot the target machine from $target."

run-euler-vm:
    @case "${EULER_VM_BOOT:-iso}" in \
      iso) \
        if [ -z "${EULER_VM_ISO:-}" ]; then \
          iso_root="$(nix build .#euler-vm-installer-iso --no-link --print-out-paths)"; \
          export EULER_VM_ISO="$(find "$iso_root/iso" -maxdepth 1 -type f -name '*.iso' -print -quit)"; \
        fi; \
        nix run .#euler-vm-installer-vm ;; \
      disk) \
        nix run .#euler-vm-installer-vm ;; \
      *) \
        echo "Unsupported EULER_VM_BOOT: ${EULER_VM_BOOT:-iso}" >&2; \
        exit 1 ;; \
    esac

run-euler-iso-vm:
    @just --justfile "{{ justfile() }}" --working-directory "{{ justfile_directory() }}" run-euler-vm

homebrew-upgrade:
    brew update
    brew upgrade
    mas upgrade

homebrew-upgrade-greedy:
    brew update
    brew upgrade --greedy
    mas upgrade

homebrew-cleanup:
    brew cleanup -s
    rm -rf "$(brew --cache)"

kind-up cluster=cluster:
    case "{{ os }}" in \
      Darwin) KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name {{ cluster }} ;; \
      Linux) systemd-run --scope --user -p "Delegate=yes" kind create cluster --name {{ cluster }} ;; \
      *) echo "Unsupported OS: {{ os }}" >&2; exit 1 ;; \
    esac

kind-down cluster=cluster:
    kind delete cluster --name {{ cluster }}

kind-list:
    kind get clusters

kind-load image cluster=cluster:
    kind load docker-image {{ image }} --name {{ cluster }}

kind-kubeconfig cluster=cluster:
    kind export kubeconfig --name {{ cluster }}

k9s cluster=cluster:
    k9s --context kind-{{ cluster }}

colima-context profile="":
    @container-context colima "{{ profile }}"

container-vms:
    @colima list || true
    @podman machine list || true

container-vms-delete-all-macos:
    @case "{{ os }}" in \
      Darwin) ;; \
      *) echo "This recipe only deletes macOS Colima/Podman VMs." >&2; exit 1 ;; \
    esac
    @if command -v colima >/dev/null 2>&1; then \
      colima list --json 2>/dev/null | jq -r 'if type == "array" then .[] elif type == "object" then . else empty end | .name // empty' | \
        while IFS= read -r profile; do \
          [[ -n "$profile" ]] || continue; \
          colima delete --force "$profile"; \
          if [[ "$profile" == "default" ]]; then context="colima"; else context="colima-$profile"; fi; \
          {{ docker }} context rm --force "$context" >/dev/null 2>&1 || true; \
        done; \
    fi
    @if command -v podman >/dev/null 2>&1; then \
      podman machine list --format json 2>/dev/null | jq -r '.[] | .Name // empty' | \
        while IFS= read -r machine; do \
          [[ -n "$machine" ]] || continue; \
          podman machine rm --force "$machine"; \
        done; \
      {{ docker }} context rm --force podman podman-root podman-rootless podman-rootful >/dev/null 2>&1 || true; \
    fi

container-colima-delete profile="default" context="colima":
    colima delete --force "{{ profile }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-colima-delete-data profile="default" context="colima":
    colima delete --force --data "{{ profile }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-podman-delete machine="podman-machine-default" context="podman-rootless":
    podman machine rm --force "{{ machine }}"
    @{{ docker }} context rm --force "{{ context }}" 2>/dev/null || true

container-podman-reset:
    podman machine reset --force
    @{{ docker }} context rm --force podman podman-root podman-rootless podman-rootful 2>/dev/null || true

container-status:
    @{{ docker }} info

container-prune:
    @{{ docker }} system prune

container-clean-all:
    @containers="$({{ docker }} container ls -aq)"; \
      if [[ -n "$containers" ]]; then \
        {{ docker }} container rm --force --volumes $containers; \
      fi
    @{{ docker }} system prune --all --volumes --force
    @{{ docker }} builder prune --all --force || true
    @{{ docker }} network prune --force || true
