#!/usr/bin/env bash
# Build the RAM-boot initramfs (cpio newc + gzip) deterministically from ramboot/initramfs-manifest.txt.
# Usage: ramboot/mkramdisk.sh <busybox-binary> <modroot-dir> <out.cpio.gz>
#   modroot-dir = kernel modules_install root (contains lib/modules/<release>/...), e.g. work/out/modroot
#   SOURCE_DATE_EPOCH must be set (kernel/build.sh prints it; it is the pinned commit time).
set -euo pipefail
BB=${1:?busybox}; MODROOT=${2:?modroot}; OUT=${3:?out.cpio.gz}
: "${SOURCE_DATE_EPOCH:?set SOURCE_DATE_EPOCH}"
HERE=$(cd "$(dirname "$0")" && pwd)
export LC_ALL=C TZ=UTC
ST=$(mktemp -d); trap 'rm -rf "$ST"' EXIT
while read -r typ path mode src; do
  case $typ in ''|'#'*) continue;; esac
  case $typ in
    dir)  mkdir -p "$ST/$path"; chmod "$mode" "$ST/$path";;
    file) case $src in init) cp "$HERE/init/init.sh" "$ST/$path";; busybox) cp "$BB" "$ST/$path";; *) echo "bad source $src" >&2; exit 1;; esac
          chmod "$mode" "$ST/$path";;
    link) ln -s "$mode" "$ST/$path";;   # for links the 3rd column is the target
    *) echo "bad manifest line: $typ $path" >&2; exit 1;;
  esac
done < "$HERE/initramfs-manifest.txt"
# modules
REL=$(cd "$MODROOT/lib/modules" && ls | head -n1)
[ -n "$REL" ] && [ "$(cd "$MODROOT/lib/modules" && ls | wc -l)" = 1 ] || { echo "need exactly one release dir in $MODROOT/lib/modules" >&2; exit 1; }
MD="$ST/lib/modules/$REL"; mkdir -p "$MD"; chmod 755 "$MD"
: > "$MD/ORDER"
while read -r m; do
  case $m in ''|'#'*) continue;; esac
  f=$(find "$MODROOT/lib/modules/$REL" -name "$m" | LC_ALL=C sort | head -n1)
  [ -n "$f" ] || { echo "module $m not found" >&2; exit 1; }
  cp "$f" "$MD/$m"; chmod 644 "$MD/$m"; echo "$m" >> "$MD/ORDER"
done < "$HERE/modules.order"
chmod 644 "$MD/ORDER"
# clamp every mtime, then archive in sorted order with fixed owner
find "$ST" -mindepth 1 -print0 | xargs -0 touch -h -d "@$SOURCE_DATE_EPOCH"
touch -d "@$SOURCE_DATE_EPOCH" "$ST"
if cpio --help 2>&1 | grep -q -- '--reproducible'; then CPIOOPT=(--reproducible); else CPIOOPT=(--renumber-inodes --ignore-devno); fi
( cd "$ST" && find . -mindepth 1 | sed 's#^\./##' | LC_ALL=C sort | cpio -o -H newc -R 0:0 "${CPIOOPT[@]}" --quiet ) | gzip -9n > "$OUT"
sha256sum "$OUT"
