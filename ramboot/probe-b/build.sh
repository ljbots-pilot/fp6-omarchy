#!/usr/bin/env bash
# Size probe: base ramdisk + one extra gzip member with one inert file /pad/probe-b.bin, padded so the total ramdisk is 58/64/90 decimal MB.
# The base cpio.gz is a byte-identical prefix; the kernel unpacks concatenated members in order. Nothing in init reads /pad.
# Usage: ramboot/probe-b/build.sh <Image.gz> <dtb> <base-ramdisk.cpio.gz> <outdir>   (SOURCE_DATE_EPOCH must be set). Only for the size-probe iteration.
set -euo pipefail
K=${1:?kernel}; D=${2:?dtb}; BASE=${3:?base}; OUT=${4:?outdir}
: "${SOURCE_DATE_EPOCH:?}"
HERE=$(cd "$(dirname "$0")" && pwd); export LC_ALL=C TZ=UTC
mkdir -p "$OUT"; bl=$(stat -c %s "$BASE")
for MB in 58 64 90; do
  T=$((MB*1000000)); L=$((T-bl-1000))
  for _ in 1 2 3 4 5 6; do
    W=$(mktemp -d); mkdir -p "$W/pad"
    python3 -c 'import hashlib,sys; sys.stdout.buffer.write(hashlib.shake_256(("fp6 probe-b %s"%sys.argv[1]).encode()).digest(int(sys.argv[2])))' "$MB" "$L" > "$W/pad/probe-b.bin"
    touch -h -d "@$SOURCE_DATE_EPOCH" "$W/pad" "$W/pad/probe-b.bin"
    (cd "$W" && printf 'pad\npad/probe-b.bin\n' | cpio -o -H newc -R 0:0 --reproducible --quiet | gzip -1n) > "$OUT/pad-$MB.cpio.gz"
    rm -rf "$W"
    s=$((bl+$(stat -c %s "$OUT/pad-$MB.cpio.gz"))); d=$((T-s)); [ $d -eq 0 ] && break; L=$((L+d))
  done
  cat "$BASE" "$OUT/pad-$MB.cpio.gz" > "$OUT/initramfs-probeb-$MB.cpio.gz"
  "$HERE/../mkbootimg.sh" "$K" "$D" "$OUT/initramfs-probeb-$MB.cpio.gz" "$OUT/boot-probeb-$MB.img"
done
