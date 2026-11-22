#!/usr/bin/env bash
# Reproducible cross build of the pinned kernel. Outputs to work/out/: Image.gz, milos-fairphone-fp6.dtb, modroot/ (stripped modules).
# Usage: kernel/build.sh            (env: WORK=dir for scratch, default <repo>/work; JOBS=n)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PIN=939a2ad25846b29eb6c33a69aa47f41ce1b2f4fc
URL=https://github.com/milos-mainline/linux
WORK=${WORK:-$ROOT/work}
SRC=$WORK/linux
OUT=$WORK/out
KB=$WORK/kbuild
JOBS=${JOBS:-$(nproc)}
mkdir -p "$WORK" "$OUT"

# 1. fetch exactly the pinned commit (no branch tip drift)
if [ ! -d "$SRC/.git" ]; then git init -q "$SRC"; fi
if ! git -C "$SRC" cat-file -e "$PIN^{commit}" 2>/dev/null; then
  git -C "$SRC" fetch -q --depth 1 "$URL" "$PIN"
fi
git -C "$SRC" checkout -q --detach -f "$PIN"
git -C "$SRC" clean -qfdx
[ "$(git -C "$SRC" rev-parse HEAD)" = "$PIN" ]

# 2. reproducibility environment (everything the kernel would otherwise take from the build host/time)
SOURCE_DATE_EPOCH=$(git -C "$SRC" log -1 --format=%ct "$PIN")
export SOURCE_DATE_EPOCH
KBUILD_BUILD_TIMESTAMP=$(LC_ALL=C date -u -d "@$SOURCE_DATE_EPOCH" '+%a %b %e %H:%M:%S UTC %Y')
export KBUILD_BUILD_TIMESTAMP
export KBUILD_BUILD_USER=builder KBUILD_BUILD_HOST=builder KBUILD_BUILD_VERSION=1
export LC_ALL=C TZ=UTC
# strip the absolute source/build paths out of the objects
export KCFLAGS="-ffile-prefix-map=$SRC=. -ffile-prefix-map=$KB=./build"
echo "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"
echo "KBUILD_BUILD_TIMESTAMP=$KBUILD_BUILD_TIMESTAMP"

# 3. our patches (empty at the start)
shopt -s nullglob
for p in "$ROOT"/kernel/patches/*.patch; do git -C "$SRC" apply --whitespace=nowarn "$p"; done

# 4. config = upstream defconfig + one fragment per variable
rm -rf "$KB"; mkdir -p "$KB"
MAKE=(make -C "$SRC" O="$KB" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang -j"$JOBS")
"${MAKE[@]}" fp6_defconfig
cmp -s "$SRC/arch/arm64/configs/fp6_defconfig" "$ROOT/kernel/config/fp6_defconfig.base" \
  || { echo "fp6_defconfig differs from kernel/config/fp6_defconfig.base (pin moved?)" >&2; exit 1; }
frags=("$ROOT"/kernel/config/fragments/*.cfg)
if [ ${#frags[@]} -gt 0 ]; then
  (cd "$KB" && "$SRC/scripts/kconfig/merge_config.sh" -m -O "$KB" "$KB/.config" "${frags[@]}")
  "${MAKE[@]}" olddefconfig
fi

# 5. build
"${MAKE[@]}" Image.gz modules dtbs
rm -rf "$OUT/modroot"
"${MAKE[@]}" modules_install INSTALL_MOD_PATH="$OUT/modroot" INSTALL_MOD_STRIP=1 DEPMOD=true
cp "$KB/arch/arm64/boot/Image.gz" "$OUT/Image.gz"
cp "$KB/arch/arm64/boot/dts/qcom/milos-fairphone-fp6.dtb" "$OUT/milos-fairphone-fp6.dtb"
( cd "$OUT" && sha256sum Image.gz milos-fairphone-fp6.dtb )
