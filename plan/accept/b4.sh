#!/bin/bash
# B4: speaker_rc is 0, and one status/*.txt line is exactly "state: RUNNING".
d=${1:-}
if [[ ! -d "$d" ]]; then
  echo "B4 ERROR reading-dir is not a directory"
  exit 2
fi
bad=0
sp="$d/speaker.txt"
ok=0
if [[ -f "$sp" ]]; then
  ok=$(awk 'NR==1{l=$0} NR>1{e=1} END{if(e==0 && l=="speaker_rc=0") print 1}' "$sp" 2>/dev/null)
fi
if [[ "$ok" != 1 ]]; then
  echo "bad: check 1 speaker.txt missing, wrong form, or speaker_rc is not 0"
  bad=$((bad + 1))
fi
hit=0
for f in "$d/status/"*.txt; do
  if [[ -f "$f" ]] && grep -qxF 'state: RUNNING' "$f"; then
    hit=1
    break
  fi
done
if [[ "$hit" -eq 0 ]]; then
  echo "bad: check 2 no status .txt has the line state: RUNNING"
  bad=$((bad + 1))
fi
if [[ "$bad" -eq 0 ]]; then
  echo "B4 PASS"
  exit 0
fi
echo "B4 FAIL bad=$bad"
exit 1
