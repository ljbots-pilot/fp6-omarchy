#!/usr/bin/env bash
# Logic-only smoke: boot the ramdisk with a generic arm64 "virt" machine and look for the init banner. This does NOT prove anything about the phone.
# Usage: tests/qemu-smoke.sh <Image> <ramdisk.cpio.gz>   rc 0 banner seen (or SKIP if qemu missing), rc 1 banner not seen
set -uo pipefail
K=${1:-work/out/Image}; R=${2:-work/out/ramdisk.cpio.gz}
command -v qemu-system-aarch64 >/dev/null 2>&1 || { echo "SKIP: qemu-system-aarch64 not installed"; exit 0; }
LOG=$(mktemp); timeout 90 qemu-system-aarch64 -M virt -cpu cortex-a72 -m 1024 -nographic -kernel "$K" -initrd "$R" -append 'console=ttyAMA0 panic=-1' > "$LOG" 2>&1 || true
if grep -q 'omarchy-mobile FP6 RAM-boot init' "$LOG"; then echo "qemu-smoke: banner seen [QEMU-only]"; rm -f "$LOG"; exit 0; fi
echo "qemu-smoke: banner NOT seen; tail:"; tail -n 20 "$LOG"; rm -f "$LOG"; exit 1
