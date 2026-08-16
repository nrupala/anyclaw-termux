---
name: termux-ai-stack
description: Operate the Termux-native AI stack (llama.cpp Vulkan build, tb bridge, backups, Maven hold/launch, process watchdog). Use for any Termux/GPU/llama.cpp/backup/Maven-stack operational task on this device.
---

# Termux AI Stack Ops

Authoritative repo: `nrupala/anyclaw-termux` (guardrails, recovery, patches, scripts). Phone names: Milan=me, Mila=Knox, Andy=opencode, Milo=openclaw.

## Bridge (tb)
- `tb status` first for anything remote; `tb exec '<cmd>'` for Termux; `tb push/pull` for files.
- SSH ConnectTimeout=5: long commands must be detached: `setsid nohup bash script.sh > log 2>&1 &`.
- Termux sshd needs Termux:Boot to persist; if dead, reopen Termux and run `sshd`.

## llama.cpp Vulkan build (Termux)
- Pinned commit `650913862`; re-apply 3 patches in `docs/PATCHES.md` after fresh clone
  (CMakeLists coopmat2 test removal, flash_attn_cm2.comp.disabled, drop `-O` in
  vulkan-shaders-gen.cpp:352 - Termux spirv-opt cannot optimize caps 4229/5447).
- Build via `/sdcard/Download/termux-bridge/build-vulkan.sh` (heat guard: pause >58C,
  resume <52C; writes `~/llama.cpp/build.done` = `done-0`). Never build hot.
- GPU check: `~/llama.cpp/build/bin/llama-bench --list-devices` -> Vulkan0 Adreno 830.
- KNOWN ISSUE: llama-bench/llama-server may segfault (rc=139) after Vulkan device init
  (Q4_K_M + this build); verify with `-ngl 0` vs `-ngl 1`. Don't claim GPU numbers until fixed.

## Models (protected)
- `/root/models` and `/sdcard/Download/models`: explicit permission from Sunny to
  delete/move/overwrite; NOTE.txt present. Copies are OK.
- Downloads are WiFi-only: confirm transport, not just WiFi presence.

## Backups
- Termux: `bash ~/.termux/backup-termux.sh` -> `/sdcard/Download/backups/termux/`
  tarball+state+components; daily cron 03:20 via `tb exec`; restore: `~/.termux/restore-termux.sh`.
- Proot: `/sdcard/Download/backups/backup.sh`; recovery layering in repo `docs/RECOVERY.md`.
- After restore verify: `node --version`, `sshd`, `vulkaninfo --summary`, `tb status`.

## Agents on Termux
- codex: `~/.local/codex/codex` (rust-v0.147.0 musl STATIC) - runs native on bionic.
- opencode: `proot-distro login debian -- /root/opencode` (v1.18.18 glibc) - needs Debian layer;
  rootfs at `$PREFIX/var/lib/proot-distro/containers/debian/rootfs` (containers/ layout, NOT installed-rootfs/).
- Debian layer: `pkg install proot-distro && proot-distro install debian`.

## Maven stack
- Hold: `touch /root/maven/state/maintenance` (launchers stand down BEFORE sourcing config);
  resume: `rm /root/maven/state/maintenance && bash /root/maven/launch-maven.sh`.
- Ports 9090/9091/9095/9096; external delegation: `touch /root/maven/state/external-{chat,coder,embed}.json`.
- Gateway stays on 127.0.0.1:9095; Termux engines reachable over shared loopback.

## Watchdog
- `proc-watchdog.py` (cron, every min): kills >=80% sustained-3min CPU spins not on
  allowlist (protects llama-server, compilers, make/ninja, cron, gateway/scheduler,
  openclaw/codexui/opencode, build-vulkan). Log `/var/log/proc-watchdog.log`.
- The watchdog does NOT kill <80% spins or crash-loop short spins; check the log.

## Networking
- Bounded probes only: `curl -m 5`. No `ss` in proot.
