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

## 2026-08-16 (cont.) — Vulkan build DONE + bench blocked

- llama.cpp Vulkan build FINISHED: `build.done = done-0` (rc 0).
  `llama-bench --list-devices` -> **Vulkan0: Adreno (TM) 830, 15209 MiB free**,
  fp16:1, int dot:1, warp 64. GPU reachable from native Termux.
- Model staged: `~/models/phi-4-mini-instruct-q4_k_m.gguf` (2.32GB copy).
- BENCH BLOCKED: llama-bench segfaults (rc=139) right after Vulkan device init
  (Q4_K_M model). CPU-only path (`-ngl 0`) not yet measured; phone hit 96C
  during CPU bench attempt -> benches STOPPED to cool. Investigate after cooldown:
  - `-ngl 0` vs `-ngl 1` isolation; GGML_VK env/debug; llama-server vs bench.
  - Suspect: unoptimized shaders or OCP/CM2 shader paths (disabled) on this pin.
- Backup components fixed: `start-sshd.sh` lives in `~/.termux/boot/` (path bug
  fixed); re-ran copies -> components/ now has 5 files. Verified on /sdcard.
- Added native skill `termux-ai-stack` (SKILL.md) in `/root/.codex/skills/` +
  repo `skills/` - tb bridge, build+patches, backups, Maven hold/launch, watchdog,
  WiFi-only downloads. Committed with this entry.

## 2026-08-16 (cont.) — Agents running + GPU bench partial

- Heat root cause: 5G modem TX during big downloads (idle zones ~95C), NOT CPU.
  Guardrail: large downloads prefer WiFi.
- GPU bench WORKS: `-ngl 1` pp512=14.06 t/s, tg32=8.01 t/s (CPU baseline 4.98/2.32).
  FULL offload `-ngl 999` segfaults (rc=139) after Vulkan init - offload-level
  specific; layer sweep was heat-gated, pending.
- proot-distro Debian installed in Termux (rootfs at
  `$PREFIX/var/lib/proot-distro/containers/debian/rootfs` - containers/ layout).
- opencode 1.18.18 RUNS in Debian layer (`/root/opencode`) - Andy live in Termux.
- codex rust-v0.147.0 MUSL STATIC runs NATIVE on bionic (`~/.local/codex/codex`,
  222MB, no interpreter) - Codex live, Debian NOT needed for it.

## 2026-08-16 (cont.) — Crash boundary mapped

- Segfault map (phi-4-mini, Vulkan): ngl=1 p512 OK; ngl=24 p512 OK; ngl=40 p64 OK;
  ngl=40 p512 CRASH (rc=139); -ngl 999 always crashes. = high-ngl + long-prompt zone.
- Stable serving config for now: `-ngl 24` (or per-model layer count minus headroom).
- Headline ngl=24 pp512/tg32 bench pending (auto watcher runs when <=58C).
