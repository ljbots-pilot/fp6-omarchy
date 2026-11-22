#!/bin/bash
bad=0
fail(){ printf 'bad: %s\n' "$1"; bad=$((bad+1)); }
[[ $# -eq 3 ]] || { printf '%s\n' "C8 ERROR need reading-dir panel-file budget-s"; exit 2; }
d=$1; p=$2; b=$3
[[ -d "$d" ]] || { printf '%s\n' "C8 ERROR reading-dir is not a directory"; exit 2; }
[[ -f "$p" && -r "$p" && -s "$p" ]] || { printf '%s\n' "C8 ERROR panel file empty or unreadable"; exit 2; }
re_b='^[1-9][0-9]{0,4}$'
[[ $b =~ $re_b ]] || { printf '%s\n' "C8 ERROR budget not a whole number from 1 to 86400"; exit 2; }
[[ $((10#$b)) -le 86400 ]] || { printf '%s\n' "C8 ERROR budget not a whole number from 1 to 86400"; exit 2; }
b=$((10#$b))
pline=
[[ $(awk 'END{print NR+0}' "$p") -eq 1 ]] && IFS= read -r pline <"$p" || true
re_p='^width=([0-9]+) height=([0-9]+) scale=([0-9]+([.][0-9]+)?)$'
[[ $pline =~ $re_p ]] || { printf '%s\n' "C8 ERROR panel file is not width=<w> height=<h> scale=<s>"; exit 2; }
pw=${BASH_REMATCH[1]}; ph=${BASH_REMATCH[2]}; ps=${BASH_REMATCH[3]}
one(){ [[ -f "$1" && -r "$1" ]] || return 1; local n; n=$(awk 'END{print NR+0}' "$1") || return 1; [[ "$n" -eq 1 ]] || return 1; LINE=; IFS= read -r LINE <"$1" || true; [[ -n $LINE ]]; }
re_t='^t0=([0-9]+) listed=([0-9]+)$'; if one "$d/timing.txt" && [[ $LINE =~ $re_t ]]; then
  t0=${BASH_REMATCH[1]}; lt=${BASH_REMATCH[2]}
  awk -v t0="$t0" -v lt="$lt" -v b="$b" 'BEGIN{exit !((lt+0)>=(t0+0) && (lt+0)-(t0+0)<=(b+0))}' || fail "check 1 listed is before t0 or past the budget"
else fail "check 1 timing.txt missing or not one line t0=<n> listed=<n>"; fi
mf="$d/monitors.json"; if [[ ! -f "$mf" || ! -r "$mf" ]]; then fail "check 2 monitors.json missing or unreadable"; else
awk -v pw="$pw" -v ph="$ph" -v ps="$ps" '{buf=buf $0 "\n"} END{
n=length(buf); dep=0; arr=0; ins=0; esc=0; key=""; good=0
for(i=1;i<=n;i++){
c=substr(buf,i,1)
if(ins){if(esc){esc=0; key=key c}else if(c=="\\")esc=1; else if(c=="\"")ins=0; else key=key c; continue}
if(c=="\""){ins=1; key=""; continue}
if(c=="["){arr++; continue}
if(c=="]"){if(arr>0)arr--; continue}
if(c=="{"){dep++; st[dep]=0; mon[dep]=(dep==1 && arr==1); continue}
if(c=="}"){if(dep>0 && mon[dep] && st[dep]==3 && wv[dep]+0==pw+0 && hv[dep]+0==ph+0 && sv[dep]+0==ps+0)good=1; if(dep>0)dep--; continue}
if(c!=":" || dep<1) continue
j=i+1; while(j<=n && substr(buf,j,1) ~ /[[:space:]]/) j++
num=""; if(substr(buf,j,1)=="-"){num="-"; j++}
if(substr(buf,j,1) !~ /[0-9]/){key=""; continue}
while(j<=n && substr(buf,j,1) ~ /[0-9]/){num=num substr(buf,j,1); j++}
if(substr(buf,j,1)=="." && substr(buf,j+1,1) ~ /[0-9]/){num=num "."; j++; while(j<=n && substr(buf,j,1) ~ /[0-9]/){num=num substr(buf,j,1); j++}}
ec=substr(buf,j,1); if(ec=="." || ec=="e" || ec=="E"){key=""; continue}
if(key=="width" && st[dep]==0){wv[dep]=num; st[dep]=1} else if(key=="height" && st[dep]==1){hv[dep]=num; st[dep]=2} else if(key=="scale" && st[dep]==2){sv[dep]=num; st[dep]=3}
key=""
}
if(good) exit 0; exit 1
}' "$mf" || fail "check 2 no monitor matches panel width height and scale"
fi
re_r='^bar_rc=([0-9]+)$'
if one "$d/bar.txt" && [[ $LINE =~ $re_r ]]; then
  [[ ${BASH_REMATCH[1]} =~ ^0+$ ]] || fail "check 3 bar_rc is not 0"
else fail "check 3 bar.txt missing or not one line bar_rc=<n>"; fi
re_c='^colors=([0-9]+) top48=([0-9]+)$'
if one "$d/colors.txt" && [[ $LINE =~ $re_c ]]; then
  awk -v n="${BASH_REMATCH[1]}" 'BEGIN{exit !(n+0>=32)}' || fail "check 4 colors is below 32"
else fail "check 4 colors.txt missing or not one line colors=<n> top48=<m>"; fi
[[ $bad -eq 0 ]] && { printf '%s\n' "C8 PASS"; exit 0; }
printf 'C8 FAIL bad=%s\n' "$bad"
exit 1
