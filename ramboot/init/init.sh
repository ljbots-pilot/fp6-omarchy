#!/bin/busybox sh
# omarchy-mobile FP6 RAM-boot init, DISPLAY+USB variant (run19, 2026-11-03)
# Adds: msm.ko + deps (DRM_MSM=m in fp6_defconfig; panel nt37705 + spi-geni are =y),
#       USB configfs gadget (ACM serial shell on ttyGS0 + NCM 172.16.42.1). No firmware.
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
B=/bin/busybox
$B mkdir -p /dev /proc /sys /tmp
$B mount -t proc proc /proc
$B mount -t sysfs sysfs /sys
$B mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
$B mount -t configfs configfs /sys/kernel/config 2>/dev/null || true
log() { echo "[omx-init] $*"; echo "[omx-init] $*" > /dev/kmsg 2>/dev/null; }

log "===== omarchy-mobile FP6 RAM-boot init (display+usb) ====="
log "$($B uname -a)"
log "cmdline: $($B cat /proc/cmdline 2>/dev/null)"

# --- USB gadget first (all USB_CONFIGFS_* are =y; no modules needed) ---
G=/sys/kernel/config/usb_gadget/omx
gadget() {
  [ -d /sys/kernel/config/usb_gadget ] || { log "no configfs usb_gadget"; return 1; }
  $B mkdir -p $G && cd $G || return 1
  echo 0x1d6b > idVendor; echo 0x0104 > idProduct
  $B mkdir -p strings/0x409 configs/c.1/strings/0x409
  echo omarchy-mobile > strings/0x409/manufacturer
  echo "FP6 RAM-boot" > strings/0x409/product
  echo omx-fp6-ramboot > strings/0x409/serialnumber
  echo "acm+ncm" > configs/c.1/strings/0x409/configuration
  $B mkdir -p functions/acm.usb0 functions/ncm.usb0
  $B ln -s functions/acm.usb0 configs/c.1/ 2>/dev/null
  $B ln -s functions/ncm.usb0 configs/c.1/ 2>/dev/null
  i=0; UDC=""
  while [ $i -lt 20 ]; do UDC=$($B ls /sys/class/udc 2>/dev/null | $B head -n1); [ -n "$UDC" ] && break; $B sleep 1; i=$((i+1)); done
  [ -n "$UDC" ] || { log "no UDC after 20s"; cd /; return 1; }
  echo "$UDC" > UDC && log "gadget bound to UDC $UDC"
  cd /
  $B sleep 1
  IF=$($B cat $G/functions/ncm.usb0/ifname 2>/dev/null); [ -n "$IF" ] || IF=usb0
  $B ifconfig "$IF" 172.16.42.1 netmask 255.255.255.0 up && log "NCM $IF = 172.16.42.1"
}
gadget || log "gadget setup failed (see dmesg)"

# --- display: load msm + deps in dependency order ---
KV=$($B uname -r); MD=/lib/modules/$KV
if [ -f $MD/ORDER ]; then
  for m in $($B cat $MD/ORDER); do $B insmod $MD/$m && log "insmod $m ok" || log "insmod $m FAILED"; done
else
  log "no $MD/ORDER (kernel release mismatch?)"
fi
$B sleep 3
log "drm: $($B ls /sys/class/drm 2>/dev/null | $B tr '\n' ' ')"
log "fb: $($B ls /dev/fb* 2>/dev/null | $B tr '\n' ' ')"
log "If you see this, RAM-boot succeeded. Host: screen /dev/ttyACM0 or ping 172.16.42.1"

# --- shells: ACM serial in background, then console ---
( while :; do [ -e /dev/ttyGS0 ] && $B setsid $B sh -c "exec $B sh </dev/ttyGS0 >/dev/ttyGS0 2>&1"; $B sleep 2; done ) &
# Pick the tty we hand to cttyhack (first that exists), then work out which
# console cttyhack really ends up on: it opens the LAST entry of
# /sys/class/tty/console/active if that node exists, else keeps our stdin (IS-F8).
CON=""
for t in /dev/ttyMSM0 /dev/tty0 /dev/console; do
  [ -e "$t" ] && { CON=$t; break; }
done
ACT=$($B cat /sys/class/tty/console/active 2>/dev/null)
REAL=${CON:-none}
if [ -n "$ACT" ] && [ -e "/dev/${ACT##* }" ]; then REAL=/dev/${ACT##* }; fi
log "console shell on $REAL (kernel active consoles: ${ACT:-unknown}; handed ${CON:-no tty} to cttyhack)"
# PID 1 must never exit (IS-F7): exit/Ctrl-D in the shell would kill init and,
# with CONFIG_PANIC_TIMEOUT=10, reboot the phone. Respawn the shell instead.
# Back-off (IF-F4, run30): a dead console tty makes every shell exit at once,
# which would respawn + log to kmsg ~1/s forever. A shell that lived < 3 s
# counts as a fast exit; the first 5 fast exits in a row still respawn after
# 1 s (a human typing exit/Ctrl-D), then the delay doubles 2,4,..,60 s (cap).
# Any shell that lived >= 3 s resets the counter and the delay to 1 s.
up() { u=$($B cut -d' ' -f1 /proc/uptime 2>/dev/null); s=${u%.*}; c=${u#*.}; c=${c#0}; echo $((${s:-0}*100+${c:-0})); }
n=0; fast=0; d=1
while :; do
  t0=$(up)
  if [ -n "$CON" ]; then
    $B setsid $B cttyhack $B sh <>"$CON" 2>&1
  else
    $B sh
  fi
  rc=$?
  n=$((n+1))
  lived=$(( $(up) - t0 ))
  if [ $lived -lt 300 ]; then fast=$((fast+1)); else fast=0; d=1; fi
  if [ $fast -gt 5 ]; then d=$((d*2)); [ $d -gt 60 ] && d=60; fi
  log "console shell exited (rc=$rc, lived $((lived*10))ms), respawn #$n in ${d}s on $REAL"
  $B sleep $d
done
