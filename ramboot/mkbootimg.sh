#!/usr/bin/env bash
# boot.img (header v2) from Image.gz + dtb + ramdisk with the recorded args in ramboot/args.txt.
# Usage: ramboot/mkbootimg.sh <Image.gz> <dtb> <ramdisk.cpio.gz> <out.img>   (runs the vendored tools/mkbootimg.py with python3; needs no host mkbootimg)
set -euo pipefail
K=${1:?kernel}; D=${2:?dtb}; R=${3:?ramdisk}; O=${4:?out}
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
mapfile -t ARGS < "$HERE/args.txt"
python3 "$ROOT/tools/mkbootimg.py" "${ARGS[@]}" --kernel "$K" --dtb "$D" --ramdisk "$R" --output "$O"
sha256sum "$O"; stat -c '%s bytes' "$O"
