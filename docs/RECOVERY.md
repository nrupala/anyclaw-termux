# Backup & Recovery — Termux-native stack

Same guiding principles as the current build env: durable copies on `/sdcard` +
GitHub, protected models, verify after restore, WiFi-only model downloads.

## Layered sources (most recent wins)
1. **GitHub** — `nrupala/anyclaw-termux` (configs, scripts, docs), plus
   maven-assistant/cortex/cortex-workzone. Survives everything.
2. **`/sdcard/Download/backups/termux/`** — Termux home tarballs + state +
   components (written by `backup-termux.sh`, daily via proot cron).
3. **`/sdcard/Download/backups/`** — proot rootfs tarballs + components
   (written by the existing `backup.sh`).
4. **`/sdcard/Download/termux-bridge/`** — bridge configs (authorized_keys,
   config.json, build scripts).

## What is NOT in the tarball (re-clone / re-download)
- `~/llama.cpp` (source on GitHub; Termux patches in `docs/PATCHES.md`).
- `node_modules` (rebuilt via `npm install`).
- Models (protected; download WiFi-only per MANIFEST.md).
- Build artifacts.

## Daily backup (already wired)
Proot cron runs: `tb exec 'bash ~/.termux/backup-termux.sh'` (daily, log at
`/var/log/termux-backup.log`). Requires Termux sshd up (`tb status` first).

## Recovery runbook
1. Install Termux (same Android user), open it once.
2. `pkg install openssh` then restore bridge: copy
   `/sdcard/Download/termux-bridge/*` into `~/.termux/` + `~/.ssh/` per DESIGN.md.
3. `bash /sdcard/Download/termux-bridge/restore-termux.sh` (or copy script in).
4. Verify: `node --version`, `sshd`, `vulkaninfo --summary`, `tb status` from proot.
5. Re-clone llama.cpp at pinned commit + re-apply `docs/PATCHES.md`, rebuild
   with heat guard (`build-vulkan.sh`).
6. Models: verify existing `/sdcard/Download/models`; if missing, WiFi-only via
   `models-download.sh --check` (never delete the NOTE.txt / protected dirs).

## Debian glibc layer
- Reinstall: `pkg install proot-distro && proot-distro install debian` (or `--override-alias debian`).
- Rootfs: `$PREFIX/var/lib/proot-distro/containers/debian/rootfs` (Termux recent layout uses `containers/`, not `installed-rootfs/`).
- opencode: `proot-distro login debian -- /root/opencode` (v1.18.18 glibc binary).
- codex: native Termux `~/.local/codex/codex` (rust-v0.147.0 musl STATIC - no Debian needed).

## Protected
- `/root/models`, `/sdcard/Download/models`, `Models` — explicit permission from
  Sunny required to delete/move/overwrite.
- Secrets live in `secrets/` and `state/` backups; never commit to GitHub.
