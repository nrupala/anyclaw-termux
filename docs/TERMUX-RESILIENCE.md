# Termux Resilience & Elevation (never killed by the system)

Goal: Termux is the most important app on the device. Make it start at boot,
hold CPU, and be exempt from Doze/App-Standby/task-kill like a Google Play
Services-grade component - as far as a non-root Android permits.

## Honest scope

- This device has NO Android root and NO custom ROM, so Termux cannot become a
  true privileged system app (priv-app on /system). That requires root or
  building it into the ROM.
- What we CAN do (verified stack): Shizuku shell/ADB identity (uid 2000) gives
  us the same `dumpsys`/`cmd appops`/`settings` power as `adb shell`. The
  exemptions below persist across reboots and are the practical equivalent of
  GMS-style protection: Doze whitelist + background appops + wake lock + boot
  autostart + Samsung "Never sleeping apps".

## What is already in place (this repo / Termux)

- `~/.termux/boot/boot-wake-lock.sh` (repo: scripts/boot-wake-lock.sh):
  `termux-wake-lock` (CPU + ongoing notification) and sshd at boot.
- `scripts/termux-elevate.sh` - the privileged one-shot (see below).
- Watchdog cron, backups, and the openclaw watch script (existing).

## One-time user steps (5 minutes)

1. Open Shizuku once and tap Start (wireless-debugging pairing if asked).
   Tell Milan "Shizuku is up" and he runs the elevate script for you.
2. Open each of these apps at least once so their boot/foreground receivers
   register: Termux, Termux:Boot, Termux:API, Termux:GUI.
3. Samsung One UI: Settings > Battery > Background usage limits >
   Never sleeping apps > add: Termux, Termux:API, Termux:Boot, Termux:GUI,
   Shizuku (and AnyClaw if you want the proot side protected too).
   Also per-app: App info > Battery > "Unrestricted" for Termux.

## Elevate (runs as shell uid, needs Shizuku up)

```bash
shizuku sh /sdcard/Download/termux-bridge/termux-elevate.sh
```

Applies for com.termux, com.termux.boot, com.termux.api, com.termux.gui,
com.termux.gui.fdroid, com.termux.tasker, moe.shizuku.privileged.api,
gptos.intelligence.assistant:

- `dumpsys deviceidle whitelist +<pkg>` (Doze + App Standby exemption)
- `cmd appops set <pkg> RUN_IN_BACKGROUND allow`
- `cmd appops set <pkg> RUN_ANY_IN_BACKGROUND allow`
- `cmd appops set <pkg> START_FOREGROUND allow`
- `cmd appops set <pkg> FOREGROUND_SERVICE allow`
- `cmd appops set <pkg> POST_NOTIFICATION allow`

All survive reboots. Run with `shizuku sh ...`; verify with the script's own
"verify" section (`dumpsys deviceidle whitelist`, `cmd appops get`).

## Optional device-wide (default OFF, affects ALL apps)

- `cmd settings put global settings_enable_monitor_phantom_procs false`
  disables the phantom-process monitor (stops system killing runaway shells).
  Tradeoff: weaker fork-bomb protection for every app. Our proc-watchdog kills
  CPU spins, so it is reasonably safe here - but it is opt-in on purpose.

## Rollback

- Doze: `dumpsys deviceidle whitelist -<pkg>`
- appops: `cmd appops set <pkg> <OP> default` or `cmd appops reset <pkg>`
- Wake lock: `termux-wake-lock` again toggles it off (or `termux-wake-unlock`).
