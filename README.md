# AnyClaw-Termux — Termux-Native Personal AI Stack

Rebuild of the AnyClaw concept (OpenClaw + Codex CLI + opencode on Android) as a
**native Termux stack** — no embedded APK runtime, no proot for the core. Hosted
by real Termux for durability, GPU access, and full control.

> Status: **work in progress**. Components are ported one at a time and proven in
> parallel before cut-over. The original proot-based stack stays live as fallback
> until each piece is verified.

## Why Termux-native

- **Durability** — Termux home survives app reinstalls. The proot rootfs that lost
  everything in a single AnyClaw reinstall is not the durable home anymore.
- **GPU** — the Adreno (Vulkan) driver is bionic-only; only native Termux can reach
  it. `llama.cpp` with Vulkan is built and served from here.
- **Footprint** — runtime dependencies only, not a full embedded distro.
- **Control** — our provisioning, our watchdog, our rules.

## Architecture

```
Android OS
   └── Termux (native, bionic)
         ├── nodejs-lts ── openclaw (Milo) · Maven gateway · chat bridge
         ├── llama.cpp (Vulkan/Adreno) ── chat/embed/coder GPU engines
         ├── codex CLI (musl static, native bionic)
         ├── sshd (tb bridge) · proc-watchdog · boot scripts (Termux:Boot)
         ├── Shizuku (Android API bridge) — planned
         └── proot-distro Debian (glibc layer, minimal)
               └── opencode (Andy) — glibc binary
```

Native Termux hosts everything that runs on Node/Python or is built from source;
a minimal Debian layer hosts the prebuilt glibc/musl CLI binaries that bionic
cannot execute directly.

## Components

| Piece | Runtime | Status |
|---|---|---|
| Termux host + package repo | bionic | ✅ live |
| `tb` sshd bridge + boot scripts | Termux | ✅ live |
| proc-watchdog (spin killer) | Termux cron | ✅ live |
| llama.cpp Vulkan build (Adreno 830) | Termux native | 🚧 building |
| nodejs-lts | Termux | ✅ live |
| openclaw (Milo) | Termux node | ⏳ port pending |
| opencode (Andy) | Debian glibc layer | ✅ running (in Termux Debian) |
| @openai/codex (Codex) | Termux native (musl static) | ✅ running (v0.147.0) |
| Maven gateway/scheduler | Termux node/python | ⏳ port last, with fallback |

## Attribution

This project rebuilds and reuses ideas from existing open-source work. We thank:

- [@OpenClawAndroid/openclaw-android-assistant](https://github.com/OpenClawAndroid/openclaw-android-assistant) — AnyClaw: the Android app that first showed three AI agents in one APK (Termux bootstrap + WebView pattern)
- [@openclaw](https://openclaw.ai) — OpenClaw gateway/assistant
- [@openai/codex](https://github.com/openai/codex) — Codex CLI
- [@sst/opencode](https://github.com/sst/opencode) — opencode terminal agent
- [@ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) — local inference engine
- [@termux](https://termux.com) — the Termux userland this runs on (GPLv3; we run on it, we do not redistribute its binaries)

This repo does **not** include the Claw Code / OpenClaude component from the
AnyClaw repo (leaked-source lineage) for licensing hygiene.

## License

Dual-licensed MIT + Apache-2.0 with a commercial-use rider. See LICENSE.md.

Copyright (c) 2026 Nrupal Akolkar.

## Docs
- [Guard rails](docs/GUARDRAILS.md) - watchdog, heat guard, backups, network rules
- [Build history](docs/BUILD_HISTORY.md) - the build history chat, appended per session
- [Backup & recovery](docs/RECOVERY.md) - layered sources, runbook
- [llama.cpp patches](docs/PATCHES.md) - Termux build patches
- [Termux resilience](docs/TERMUX-RESILIENCE.md) - keep Termux alive/elevated
- [Announcement draft](docs/ANNOUNCEMENT.md)
