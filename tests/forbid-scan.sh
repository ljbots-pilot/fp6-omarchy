#!/usr/bin/env bash
# Scans ONLY this repo's own tracked files (never the fetched kernel tree under work/) against tests/forbid.txt.
# tests/forbid.txt itself is excluded (it contains the patterns).
# Usage: tests/forbid-scan.sh                 rc 0 clean, rc 1 hit
#        tests/forbid-scan.sh --paths <base>  also check that `git diff <base>...HEAD` touches only tests/agent-writable.txt prefixes (rc 1 if not)
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT" || exit 1
rc=0
if git rev-parse --git-dir >/dev/null 2>&1; then
  mapfile -t FILES < <(git ls-files --cached --others --exclude-standard)
else
  mapfile -t FILES < <(find . -type f -not -path './work/*' -not -path './.git/*' | sed 's#^\./##')
fi
for f in "${FILES[@]}"; do
  [ "$f" = tests/forbid.txt ] && continue
  [ -f "$f" ] || continue
  if grep -I -n -E -f tests/forbid.txt -- "$f"; then echo "forbid-scan: HIT in $f" >&2; rc=1; fi
done
if [ "${1:-}" = --paths ]; then
  base=${2:?base}
  while read -r f; do
    ok=0
    while read -r p; do case $f in "$p"*) ok=1;; esac; done < tests/agent-writable.txt
    [ $ok = 1 ] || { echo "forbid-scan: path not allowed for agent: $f" >&2; rc=1; }
  done < <(git diff --name-only "$base"...HEAD)
fi
[ $rc = 0 ] && echo "forbid-scan: clean (${#FILES[@]} files)"
exit $rc
