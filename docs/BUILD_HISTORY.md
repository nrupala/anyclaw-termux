# Build History

Dated log of builds, ports, and decisions. Append per session; never rewrite history.

## 2026-08-16 — Termux-native stack kickoff

- Decision (user): Option A - real Termux as host. Maven stays phone-native;
  laptop server is a parked future extension. Laptop CUDA build kit archived at
  `/sdcard/Download/Projects/sharable/code/`.
- Decision (user): publish own repo under MIT + commercial rider, acknowledge
  original builders, exclude leaked Claude Code component.
- Repo `nrupala/anyclaw-termux` scaffolded, committed (`cafaca9`), pushed public.
- Termux: `nodejs-lts` v24.18.0 + npm 11.19.0 installed. `tb` bridge + sshd live.
- opencode 1.18.18 finding: BOTH release binaries are dynamically linked
  (glibc `/lib/ld-linux-aarch64.so.1`, musl `/lib/ld-musl-aarch64.so.1`) - no
  static build exists, so opencode (Andy) needs the Debian glibc layer, not
  native bionic. npm install also refuses: `EBADPLATFORM` (os=android).
- llama.cpp Vulkan build: shader blocker fixed by dropping `-O` from
  `vulkan-shaders-gen.cpp:352` (Termux spirv-opt cannot optimize capabilities
  4229/5447). Build progressing heat-guarded (65-66%, ~65C) as of this entry.

## 2026-08-16 (cont.) — Termux backup & recovery

- Added `scripts/backup-termux.sh` + `scripts/restore-termux.sh` (mirror proot
  backup.sh conventions: timestamped tar -> /sdcard/Download/backups/termux,
  state/ + components/, keep last 10). Excludes llama.cpp, node_modules,
  caches; re-clone/re-apply via docs/PATCHES.md.
- Installed into Termux (`~/.termux/backup-termux.sh`), baseline run OK:
  `termux-home-20260816-135017.tar.gz` (16K - home is mostly excluded
  llama.cpp/build).
- Daily cron wired (03:20 UTC): `tb exec 'bash ~/.termux/backup-termux.sh'`,
  log `/var/log/termux-backup.log`.
- Added docs/RECOVERY.md (layered sources + runbook) + docs/PATCHES.md
  (3 llama.cpp Termux patches at 650913862).
