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

## 2026-08-16 (cont.) — opencode-native feasibility: BLOCKED by Bun, not by us

- Probed sst/opencode@main source: CLI (packages/opencode, v1.18.18) builds via
  `bun run script/build.ts` -> `bun build --compile`. Targets emitted: linux
  arm64/x64 (glibc), linux musl, darwin. NO android/bionic target exists.
- Runtime is Bun; bin/opencode is a Node wrapper that spawns the compiled binary.
  The dynamic glibc/musl binaries are a direct consequence of Bun's target list.
- Verdict: opencode-native-on-bionic is blocked upstream (Bun has no Android
  target), NOT a quick win. Debian layer remains ONLY for opencode. codex is
  already native (musl static), openclaw/Maven are node-native, llama.cpp GPU
  native. When Bun ships Android support, opencode-native becomes a one-liner.
- Probe clone kept at /root/probe/o (shallow, sst/opencode@main).

## 2026-08-16 (cont.) — Bench numbers + GPU wiring prep

- Auto-bench (ngl=24, Vulkan, -t 4): pp512 = 11.75 t/s, tg32 = 7.50 t/s.
  CPU baseline: 4.98 / 2.32 -> ~2.4-3.2x. (ngl=1 earlier: 14.06 / 8.01.)
- Added scripts/termux-llama-server.sh (chat 9090 + embed 9096 on loopback, ngl=24,
  -fa on, ctx 8192) + docs/MAVEN-GPU-WIRING.md (markers, resume, rollback).
  NOT activated - Maven still on maintenance hold; activation when user resumes.
- Proot agent versions to match in Termux: openclaw 2026.3.8, codex 0.147.0,
  opencode-ai 1.18.18, codexui-android 0.1.92.

## 2026-08-16 (cont.) — OpenClaw (Milo) live in Termux (parallel instance)

- Copied /root/.openclaw -> Termux ~/.openclaw-termux (profile "termux"; logs excluded;
  secrets stay device-local, NOT in git). WhatsApp DISABLED in the copy
  (channels.whatsapp + plugins.entries.whatsapp = false) - baileys code path inert.
- Running: `openclaw --profile termux gateway --port 18790` (loopback, PID live,
  canvas 18790, browser ctrl 18792, heartbeat + health-monitor up).
- Proot's Milo untouched on default port (parallel). Cut-over/who-owns-what later.
- Watchdog: ~/.termux/watch-openclaw.sh (1-min cron via tb) - verified "up".
- Baileys advisory (GHSA-qvv5-jq5g-4cgg): rc.9 still installed (unused - WhatsApp
  off). Plan: pin 7.0.0-rc12+ via npm overrides on WiFi before enabling WhatsApp.
  NOTE proot Milo STILL runs WhatsApp on rc.9 - recommend pinning/disable before use.

## 2026-08-16 (cont.) — Termux env finish: WhatsApp on, baileys rc12, Python/auth confirmed

- WhatsApp ENABLED in Termux openclaw (profile termux): channels.whatsapp.enabled
  + plugins.entries.whatsapp.enabled = true; dmPolicy=pairing, groupPolicy=open
  (kept open until real allowlist IDs supplied).
- Baileys pinned 7.0.0-rc12 (fixes GHSA-qvv5-jq5g-4cgg): global
  @whiskeysockets/baileys@7.0.0-rc12 installed + nested copy under
  node_modules/openclaw/node_modules/@whiskeysockets/baileys replaced.
  Verified: npm ls -g; nested package.json = 7.0.0-rc12; gateway 18790 http 200.
- Added scripts/re-pin-baileys.sh + ~/.termux/re-pin-baileys.sh: re-apply after
  any openclaw update (npm overrides alone do not survive a global reinstall).
- Linking runbook (user step): `openclaw --profile termux channels login
  --channel whatsapp` (QR in TTY) or Control UI dashboard; verify via
  `channels status --probe`. NOT YET LINKED.
- Python in Termux: ALREADY INSTALLED, no action needed (python 3.14.6).
- codex 0.147.0 native (musl static) in Termux: login status = "Logged in using
  ChatGPT" (real session, no bypass). Auth/config copied from proot; live JWTs
  stay on-device, never committed.
- openclaw skills symlink: ~/.openclaw-termux/skills -> ~/.shared-skills (OK).
- CONFLICT notice: proot Milo still WhatsApp-enabled on baileys rc.9; one number
  = one active session. Pin proot Milo to rc12 or disable its WhatsApp before
  linking Termux Milo.
## 2026-08-16 (cont.) — Termux elevation applied + proot->Termux data sync

- Shizuku confirmed up (uid 2000 shell). Ran scripts/termux-elevate.sh:
  - deviceidle whitelist (verified in `dumpsys deviceidle whitelist`):
    com.termux, com.termux.api, com.termux.boot, com.termux.gui,
    moe.shizuku.privileged.api, gptos.intelligence.assistant.
  - appops allow: RUN_IN_BACKGROUND, RUN_ANY_IN_BACKGROUND, START_FOREGROUND,
    POST_NOTIFICATION for all 8 candidate packages. All persist across reboots.
  - Phantom-process-monitor disable kept OFF (device-wide, opt-in).
- proot -> Termux data sync over tb bridge (tarball, excludes shared_skills/.git
  link2symlink artifacts):
  - ~/.shared-skills fully mirrored (.system + shared_skills + termux-ai-stack).
  - ~/.codex/skills now a symlink to ~/.shared-skills (mirrors proot layout);
    .codex config/auth/memories/plugins were already identical (mtimes matched).
  - ~/.ssh: id_ed25519(+pub), id_termux(+pub), known_hosts (authorized_keys kept).
  - ~/.gitconfig: copied, gh helper path patched /usr/bin/gh ->
    /data/data/com.termux/files/usr/bin/gh; global identity set
    nrupala <51525601+nrupala@users.noreply.github.com>.
  - ~/.config/gh: hosts.yml token copied (device-local, not in git).
- gh 2.97.0 installed in Termux; `gh auth status` = Logged in as nrupala
  (https protocol, scopes read:org read:user repo user:email workflow).
  Termux can now push to GitHub on its own.
- OpenClaw skills symlink intact: ~/.openclaw-termux/skills -> ~/.shared-skills.
## 2026-08-16 (cont.) — WhatsApp linked + Cloudflare identity configured

- WhatsApp LINKED on Termux openclaw (profile termux): session store present at
  ~/.openclaw-termux/credentials/whatsapp/default (creds.json + signal pre-keys).
  Gateway log 17:24: starting provider (+17808801326), 17:24:51 "Listening for
  personal WhatsApp inbound messages." NOTE: `channels status --probe` may
  briefly report "not linked" right after linking / after gateway restarts; the
  gateway log + credentials dir are authoritative.
- PROOT Milo still has WhatsApp enabled on baileys rc.9 - pin to rc12 or disable
  before use; only ONE active session per number (Termux Milo is now the live
  WhatsApp path).
- Cloudflare identity configured + verified:
  - Token persisted as CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID in
    /root/.secrets.env and ~/.secrets.env (Termux), chmod 600, sourced from
    .bashrc/.profile. NEVER committed to git.
  - Token verify: active. Live Workers AI inference OK: account
    2edd59d09fd816187b47afbb9ea43af1, model @cf/meta/llama-3.3-70b-instruct-fp8-fast
    returned completion. codex config.toml [model_providers.cloudflare] already
    points at this account (env_key CLOUDFLARE_API_TOKEN).
  - Maven providers.json does NOT include a CF entry; deepseek/offgrid/xform/
    claude/copilot entries present with api_key placeholders - Maven-side
    provider wiring still pending user's model choices.
- Samsung "Never sleeping apps" note: the UI list can omit apps already exempted
  via `dumpsys deviceidle whitelist` (shell-side exemption = same effect). If the
  list still feels incomplete, per-app path: Settings > Apps > <app> > Battery >
  "Unrestricted".
## 2026-08-16 (cont.) — MAVEN ACTIVATED on Termux GPU (user go)

- Maintenance hold lifted (rm /root/maven/state/maintenance); markers
  external-chat.json + external-embed.json created; bash launch-maven.sh.
- Termux engines (Vulkan, -ngl 24, -t 4): chat 9090 = phi-4-mini (fa on, ctx
  8192, slots 4) UP; embed 9096 = nomic-embed (ctx 4096) UP. Both health 200.
- BUGFIX in scripts/termux-llama-server.sh: `--embedding on` -> `--embedding`
  (flag takes no value; embed server failed to start with the old arg).
- proot stack: gateway 9095 (http 302 -> login, pid 29855) + scheduler
  (pid 29862) UP. Coder engine NOT started: state/thermal-hold present ->
  launcher coder branch skipped silently (no external-coder marker). Coding
  (qwen-coder-7b) engine remains off until RAM/hectare review.
- Live GPU inference verified via 9090 /v1/chat/completions (engine responded).
- AUDIT (user asked temp/ram/storage):
  - Temp: max zone 71.6C (cpu-1-1-1), spiked 84.2C during inference, cooling;
    below 95C alarm zone, above 40C idle target. Watch sustained >80C.
  - RAM: MemTotal 11.4G, MemAvailable ~1.2G, swap 16G (5.7G used). Termux chat
    llama-server RSS 1.72G, embed 21M; openclaw-gateway RSS 434M.
  - Storage: 220G total, 203G used (93%), ~17G free - matches "16GB" reading.
    /sdcard/Download/models = 17G (model library); recent adds = none beyond
    models + 363M rootfs backup. No leak; space = models + existing backups.
  - Optional reclaim (needs Sunny permission, models are protected): offload
    qwen3-4b 2.5G / llama-3.2 2G / qwen2.5-vl 1.9G+mmproj 1.3G if unused.
## 2026-08-16 (cont.) — Maven login persistence fixed (user report: booted on refresh)

- Root causes: (1) web app stored the session token ONLY in localStorage and
  ignored the 7-day cookie the login page sets -> any localStorage loss
  (storage pressure, browser cleanup, origin change) = 401 on refresh ->
  hard redirect to /login. (2) Vault DEK is in-memory by design -> refresh
  always re-asked for master password.
- Fixes (committed cf2a552 @ nrupala/maven-assistant, main):
  - web/lib/api.js getToken(): falls back to the 7-day maven_token cookie and
    migrates it back into localStorage (survives eviction).
  - gateway.js legacy inline pages (/chat, /keys) got the same fallback.
  - web/lib/vault.js + web/app.js: "Keep unlocked for 7 days" on the unlock
    gate (default on); boot auto-restores via tryRemember(); explicit Lock
    clears the record; idle auto-lock keeps the record.
- Verified live: cookie-only /api/whoami = 200; /, /chat, /keys serve with
  cookie and contain the fallback; SPA intact. Gateway restarted (pid file,
  plugins online) to load the fix.
- Ops notes: gateway restarted via direct setsid nohup node (launcher was
  briefly locked by a stuck run: two launch-maven.sh attempts logged "launch
  skipped: another launcher is running"; cleared). /root/maven launcher files
  (launch-common.sh, launch-maven.sh, maven-watchdog.sh, maven-build-log.md)
  have UNCOMMITTED in-progress edits - left untouched.
## 2026-08-17 — Two Maven UIs (APK + browser) on 9095 + heat tune

- User has Maven open in the APK (com.maven.assistant 0.6.3) AND a browser;
  both target the same gateway 127.0.0.1:9095. Confirmed single backend, two
  clients - by design (APK is a web client of the same gateway). Each client
  keeps its own token storage; the 7-day login fix (cf2a552) applies per client.
- Old 6-Aug build verification: netstat via shizuku shows NO listeners on
  8080-8085; only one maven package installed (com.maven.assistant 0.6.3) -
  the legacy build is already gone. Only stack listeners: 9090/9095/9096
  (+openclaw 18790-18793, sshd 8022).
- Heat: cores hit 77-84C with chat GPU server active (28-32% CPU = 4 prompt
  threads). Applied single KV slot: chat restarted with --parallel 1
  (same ctx 8192, fa on, ngl 24, -t 4). Temps: 84 -> 77 -> 73C. If still hot:
  lower to -t 2 or ctx 4096 (user decision).
- Note: two ESTABLISHED WARP (192.0.0.8/172.18.x) connections to 43.175.230.151:8080
  - Cloudflare WARP tunnel active; modem/WARP traffic also contributes heat.
- scripts/termux-llama-server.sh patched with --parallel 1 (repo + /sdcard staged).
## 2026-08-17 (cont.) — Chat model unloaded (heat), CPU/GPU split explained

- User approved unloading chat: Termux chat GPU server (9090, phi-4-mini)
  stopped and its pid file cleared; verified no llama-server process remains
  and embed RAG (9096, nomic) stays up. Gateway healthy; chat request now
  returns "model cold start failed" (no local CPU engine spawns - external
  chat marker keeps the launcher from starting a local one).
- Why CPU shows when GPU serving: llama.cpp keeps CPU threads for prompt
  processing/prefill/tokenization even with -ngl 24; on this Adreno 830 build
  PP is largely CPU-bound (no matrix cores; bench: pp speed ~flat vs -ngl).
  Generation math runs on Vulkan. ~30% CPU is transient per-request; idle ~0.
- To bring chat back: `tb exec 'bash /sdcard/Download/termux-bridge/termux-llama-server.sh'`.
  GAP (future): external cold-start isn't wired to relaunch the Termux GPU
  script, so unloaded chat requires a manual reload (by Sunny or via agent).
- Shizuku: NOT needed for normal ops now - Doze whitelist + appops persist
  across reboots without the server. Keep installed; start only for privileged
  actions (re-run termux-elevate.sh, dumpsys, UI automation).
## 2026-08-17 (cont.) — Low-power daemon profile + user manual in Maven GUI

- Maven now behaves as an on-demand intelligent engine: gateway 9095 +
  scheduler always up (idle CPU ~0% for node gateway and python3 scheduler),
  chat is optional and currently unloaded.
- state/config.json `model_idle_stop_min: 5`: reasoning plugin stops chat after
  5 idle minutes; restart of the Termux GPU engine remains manual by design
  (external-chat.json marker keeps the launcher from spawning a local one, so
  "model cold start failed" is the intended response while chat is unloaded).
- Shipped `/docs` user-manual route to maven-assistant: lightweight markdown
  renderer in gateway.js (headers/tables/code/list/links, HTML-escaped, zero
  deps) serving docs/USER-MANUAL.md behind login like every other page.
  Maven commits pushed: c22e6cd (manual route) + 1739b7f (low-power daemon).
- Low-power daemon commits (maven-assistant): adaptive chat ctx
  8192->16384 floor/ceiling from MemAvailable; THREADS 8->4; --flash-attn on;
  launcher flock + maintenance hold; coder memory gate CODER_MEM_MIN_MB=6144
  mirrored in launcher + watchdog; external-chat/coder/embed markers honored
  by launcher and watchdog (no local CPU llama-server spawns).
- Verified live: gateway restarted on new code at 0.0.0.0:9095, /api/health
  200, /docs wired (302->/login unauthenticated). Battery ~79% charging, core
  43.2C, max thermal zone ~73.5C (cooling from 77-84C).
## 2026-08-17 — Local llama.cpp for ALL agents (codex + opencode + openclaw)

- Goal: run every agent on-device on our own models (no provider rate limits,
  no mobile-data LLM calls). Winner vs. any proxy: plain llama.cpp directly,
  the same engine Maven uses - agents bypass the gateway and hit
  `http://127.0.0.1:9090/v1` (Termux llama-server, loopback is shared).
- Model policy (power/heat/quality): phi-4-mini (2.49GB) DEFAULT - lowest power,
  great quality/speed for chat+agents; qwen3-4b (2.5GB, ctx 16384) for stronger
  agentic/tool fidelity; qwen2.5-coder-7b only on 9091 when cool (thermal/RAM
  gated). One engine loaded at a time.
- codex (~/.codex/config.toml proot + Termux): added [model_providers.local]
  wire_api="chat", env_key=LOCAL_LLM_KEY (exported in .bashrc both sides).
  Run: `LOCAL_LLM_KEY=local codex --provider local -m phi-4-mini [--model qwen3-4b]`.
- opencode (~/.config/opencode/opencode.jsonc proot + Debian rootfs copy):
  provider "local" (@ai-sdk/openai-compatible, baseURL 9090/v1) with
  phi-4-mini / qwen3-4b / qwen2.5-coder-7b; agent "local" = minimal on-device
  toolset (bash/read/edit/glob/grep). Run: `opencode run -m local/phi-4-mini`.
- openclaw (proot ~/.openclaw + Termux ~/.openclaw-termux): openai-compatible
  provider baseUrl -> 127.0.0.1:9090/v1, models phi-4-mini + qwen3-4b,
  default primary openai-compatible/phi-4-mini. OpenRouter/OpenAI keys kept as
  fallback profiles; llama.cpp ignores the Authorization header.
- scripts/agent-engine.sh (Termux, also staged /sdcard/Download/termux-bridge/
  and ~/bin): start|stop|status for the 9090 engine, AGENT_MODEL select,
  heat guard >=78C refuses start, pidfile shared with Maven chat (chat-gpu.pid).
- PENDING (blocked by heat, max zone 80.7C and rising/charging): live smoke
  test of one agent round-trip. Configs are syntax-validated. When cool:
  `tb exec 'bash ~/bin/agent-engine.sh start'` then
  curl 9090/v1/models, codex/opencode smoke, stop when done.
## 2026-08-17 — CRITICAL: pinned Vulkan build CORRUPTS Q4_K_M output on GPU

- Tested phi-4-mini AND qwen3-4b (both Q4_K_M): ANY GPU offload corrupts
  generation. Output = repeated '@' up to max_tokens, for -ngl 1, 8, 16, 24;
  flash-attn on/off; default vs q8_0 KV cache: identical garbage.
- -ngl 0 (CPU-only) output is CORRECT (2+2 -> "4"). Model files are fine.
- Verdict: the Vulkan compute path in pinned build (commit 650913862 + 3
  patches) silently produces garbage for Q4_K_M on Adreno 830 - it does not
  crash, it answers wrong. Health checks pass because the server responds;
  this explains the earlier "chat works though struggle" reports. GPU was
  NEVER actually usable on this build - critical correction to prior notes.
- Rectify ladder: (1) rebuild llama.cpp from a newer commit (Vulkan/Q4_K_M
  shader fixes), then re-run ngl ladder; (2) until then chat/agents run CPU
  (-ngl 0) via agent-engine.sh (default now NGL=0); (3) optional test: Q8_0
  or F16 quant on the current build - if non-Q4_K_M dequant avoids the broken
  shaders we regain GPU without a rebuild.
- agent-engine.sh fixed: setsid nohup + redirect on ONE line (previous sed
  broke the line, $! was wrong and the server held the ssh session open);
  readiness poll waits for /v1/models (model load ~5-15s); heat guard 78C;
  NGL env selectable (default 0 = CPU verified; 16/24 only after rebuild).
- Speed reference (phi-4-mini): CPU tg ~2.3 t/s / pp ~5 t/s but correct;
  GPU tg ~7.3 t/s but garbage. Correctness beats speed until rebuild.


## 2026-08-17 - WhatsApp unlinked from Milo (Termux + proot)

- Why: two unpaired contacts DM'd Milo's WhatsApp line (~7:21p and ~7:31p
  MST on 08-16); the `dmPolicy: pairing` flow auto-replied to each with a
  pairing code, which showed up as "Milo pinging <contact> to pair". Codes
  were never completed, so neither contact gained any access.
- Action (owner-requested): disconnect WhatsApp entirely.
- Termux (profile termux, gateway 18790): channels.whatsapp.enabled + plugins.
  entries.whatsapp.enabled -> false; WhatsApp session credentials and the
  pairing-request store moved out of active use to
  ~/backups/whatsapp-unlink-2026-08-17/ (recoverable; also covered by the
  daily termux backup). Gateway restarted; startup log shows NO whatsapp init.
- Proot (gateway 18789): same config flags set false as precaution (it holds
  no WhatsApp session credentials anyway; takes effect on next restart).
- Re-link later if ever wanted: restore creds from the backup folder, set both
  flags true, restart the gateway, re-scan QR.
