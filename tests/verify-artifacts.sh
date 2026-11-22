#!/usr/bin/env bash
# Recompute size + sha256 of every artifact in results/MANIFEST.sha256 (rows: "<sha256>  <size>  <name>") against work/out/<name>.
# rc 0 all match, rc 1 mismatch or missing file, rc 2 manifest empty.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT" || exit 1
M=${MANIFEST:-results/MANIFEST.sha256}; D=${OUTDIR:-work/out}
n=0; rc=0
while read -r sha size name; do
  case $sha in ''|'#'*) continue;; esac
  n=$((n+1))
  f=$D/$name
  [ -f "$f" ] || { echo "MISSING $name"; rc=1; continue; }
  as=$(sha256sum "$f" | cut -d' ' -f1); az=$(stat -c %s "$f")
  if [ "$as" = "$sha" ] && [ "$az" = "$size" ]; then echo "OK $name"; else echo "MISMATCH $name want $sha/$size got $as/$az"; rc=1; fi
done < "$M"
[ $n -gt 0 ] || { echo "manifest has no rows"; exit 2; }
exit $rc
