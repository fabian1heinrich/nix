#!/usr/bin/env bash
set -euo pipefail

: "${EULER_VM_ISO:?missing euler installer ISO path}"
: "${EULER_VM_OVMF_CODE:?missing OVMF_CODE.fd path}"
: "${EULER_VM_OVMF_VARS_SRC:?missing OVMF_VARS.fd path}"

state_dir="${EULER_VM_DIR:-$PWD/.euler-vm}"
disk="${EULER_VM_DISK:-$state_dir/euler.qcow2}"
disk_size="${EULER_VM_DISK_SIZE:-64G}"
memory="${EULER_VM_MEMORY:-4096}"
cpus="${EULER_VM_CPUS:-4}"
ovmf_vars="$state_dir/OVMF_VARS.fd"
display="${EULER_VM_DISPLAY:-auto}"
boot="${EULER_VM_BOOT:-iso}"

mkdir -p "$state_dir"

if [ ! -e "$disk" ]; then
  qemu-img create -f qcow2 "$disk" "$disk_size"
fi

if [ ! -e "$ovmf_vars" ]; then
  cp "$EULER_VM_OVMF_VARS_SRC" "$ovmf_vars"
  chmod u+w "$ovmf_vars"
fi

accel=tcg
cpu=max
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  accel=kvm
  cpu=host
fi

case "$display" in
  auto)
    display_args=(-nographic)
    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
      display_args=(-display gtk)
    fi
    ;;
  gtk)
    display_args=(-display gtk)
    ;;
  nographic)
    display_args=(-nographic)
    ;;
  *)
    echo "Unsupported EULER_VM_DISPLAY: $display" >&2
    exit 1
    ;;
esac

net_args=(-nic none)
if [ "${EULER_VM_NET:-none}" = "user" ]; then
  net_args=(-nic "user,model=virtio-net-pci")
fi

case "$boot" in
  iso)
    boot_args=(-cdrom "$EULER_VM_ISO" -boot d)
    ;;
  disk)
    boot_args=(-boot c)
    ;;
  *)
    echo "Unsupported EULER_VM_BOOT: $boot" >&2
    exit 1
    ;;
esac

exec qemu-system-x86_64 \
  -name euler \
  -machine "q35,accel=$accel" \
  -cpu "$cpu" \
  -m "$memory" \
  -smp "$cpus" \
  -drive "if=pflash,format=raw,readonly=on,file=$EULER_VM_OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$ovmf_vars" \
  -drive "file=$disk,if=virtio,format=qcow2" \
  "${boot_args[@]}" \
  "${display_args[@]}" \
  "${net_args[@]}" \
  "$@"
