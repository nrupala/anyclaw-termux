# Build Guard Rails

Same protections as the Maven build. Apply to every build/port in this stack.

## Process watchdog
`proc-watchdog.py` runs from cron every minute. It kills any process holding
>=80% CPU for a sustained 3 minutes that is NOT on the allowlist.

Allowlist (never killed): llama-server, compilers (cc/clang/g++), cmake, make,
ninja, git, cron, thermal-monitor, sshd, openclaw/codexui/opencode, Maven
gateway/scheduler, and any cmdline matching `gateway.js|scheduler.py|openclaw|
codexui|llama.cpp|build-vulkan|proc-watchdog`.

Log: `/var/log/proc-watchdog.log`  State: `/root/maven/state/procwatch`

## Heat guard
Builds pause above 58C and resume below 52C (implemented in
`build-vulkan.sh` for the llama.cpp Vulkan build). Never run heavy builds
unattended without this. Phone target: keep under 40C at idle when charging.

## Single instance
Launchers take an `flock` lock - only one instance runs. Stuck subshells
are killable (`kill -9` if SIGTERM is ignored mid-compute).

## Maintenance hold
`state/maintenance` stands down launchers BEFORE config is sourced. Removing
it resumes. Server processes: gateway/chat/embed/coder.

## Backups
- `/sdcard/Download/backups/` (state, crontab, configs)
- GitHub push (this repo + maven-assistant + cortex) after each milestone.
- Protected models: `/root/models` + `/sdcard/Download/models` - explicit
  permission from Sunny required to delete/move/overwrite. NOTE.txt present.

## Termux resilience
Termux is the primary host and must not be killed by the system. Runbook:
`docs/TERMUX-RESILIENCE.md` (boot wake lock, Doze/appops elevation via
Shizuku, Samsung "Never sleeping apps", rollback). Run the elevate script
whenever Shizuku is up: `shizuku sh /sdcard/Download/termux-bridge/termux-elevate.sh`.

## Network
- Large downloads (rootfs, toolchains, binaries >50MB) also prefer WiFi: 5G modem TX heats the radio and can spike zone temps to ~95C with zero CPU load; model rule below stays hard WiFi-only.
- Model downloads: WiFi-only. Confirm the transport is WiFi before
  starting/resuming, not merely that WiFi is connected.
- Health probes are bounded (`curl -m 5`); never `ss` in proot.

## Build history
Every session appends to `docs/BUILD_HISTORY.md` in this repo - decisions,
commands, failures, and outcomes. This file IS the build history chat.
