#!/usr/bin/env bash
# Syntax-check ramboot/init/init.sh with busybox ash (if available) or sh, and scan it with the forbid list.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT" || exit 1
rc=0
F=ramboot/init/init.sh
if [ -x work/busybox-aarch64 ] && command -v qemu-aarch64-static >/dev/null 2>&1; then qemu-aarch64-static work/busybox-aarch64 sh -n "$F" || rc=1
else sh -n "$F" || rc=1; fi
if grep -n -E -f tests/forbid.txt "$F"; then echo "lint-init: forbidden pattern in $F" >&2; rc=1; fi
bash -n ramboot/mkramdisk.sh ramboot/mkbootimg.sh ramboot/fetch-busybox.sh ramboot/probe-b/build.sh kernel/build.sh tests/*.sh || rc=1
[ $rc = 0 ] && echo "lint-init: ok"
exit $rc
