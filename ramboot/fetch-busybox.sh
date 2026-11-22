#!/usr/bin/env bash
# Fetch the pinned static aarch64 busybox (Ubuntu busybox-static 1:1.37.0-7ubuntu1) and extract bin/busybox to work/busybox-aarch64.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); WORK=${WORK:-$ROOT/work}; mkdir -p "$WORK"
DEB_URL=https://ports.ubuntu.com/ubuntu-ports/pool/main/b/busybox/busybox-static_1.37.0-7ubuntu1_arm64.deb
DEB_SHA=fcf50794faf920455895d7ef103d1c54b9ebf7f18d2e52982dbf3903b7769592
BIN_SHA=c2f279d1d5640a0f327890d41cad594c0f059f3fed3f96dd72fdcc4f5e18ec02
[ -f "$WORK/busybox-aarch64" ] && echo "$BIN_SHA  $WORK/busybox-aarch64" | sha256sum -c --quiet - && exit 0
curl -fsSL -o "$WORK/busybox-static.deb" "$DEB_URL"
echo "$DEB_SHA  $WORK/busybox-static.deb" | sha256sum -c --quiet -
rm -rf "$WORK/bbx"; mkdir -p "$WORK/bbx"; dpkg-deb -x "$WORK/busybox-static.deb" "$WORK/bbx"
cp "$WORK/bbx/usr/bin/busybox" "$WORK/busybox-aarch64" 2>/dev/null || cp "$WORK/bbx/bin/busybox" "$WORK/busybox-aarch64"
echo "$BIN_SHA  $WORK/busybox-aarch64" | sha256sum -c --quiet -
echo "busybox ok: $WORK/busybox-aarch64"
