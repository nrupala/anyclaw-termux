#!/system/bin/sh
# Elevate the Termux stack (and AnyClaw host) to Google-Play-services-like
# resilience: Doze whitelist + background/foreground appops. Survives reboots.
# Run from proot once Shizuku is running:
#   shizuku sh /sdcard/Download/termux-bridge/termux-elevate.sh
set -u

PACKAGES="com.termux com.termux.boot com.termux.api com.termux.gui com.termux.gui.fdroid com.termux.tasker moe.shizuku.privileged.api gptos.intelligence.assistant"

echo "== deviceidle (Doze/App-Standby) whitelist =="
for p in $PACKAGES; do
  if dumpsys deviceidle whitelist +"$p" >/dev/null 2>&1; then
    echo "whitelisted: $p"
  fi
done

echo "== appops: background + foreground + notifications =="
for p in $PACKAGES; do
  for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND START_FOREGROUND FOREGROUND_SERVICE POST_NOTIFICATION; do
    if cmd appops set "$p" "$op" allow >/dev/null 2>&1; then
      echo "appops allow: $p $op"
    fi
  done
done

echo "== optional (device-wide, NOT applied): disable phantom-process monitor =="
echo "# cmd settings put global settings_enable_monitor_phantom_procs false"

echo "== verify: Doze whitelist (termux/shizuku/gptos) =="
dumpsys deviceidle whitelist | grep -E 'termux|shizuku|gptos' | head -20

echo "== verify: appops per package =="
for p in $PACKAGES; do
  echo "-- $p"
  cmd appops get "$p" 2>/dev/null | grep -E 'RUN_IN_BACKGROUND|RUN_ANY_IN_BACKGROUND|START_FOREGROUND|FOREGROUND_SERVICE|POST_NOTIFICATION' | head -6
done
echo "DONE"
