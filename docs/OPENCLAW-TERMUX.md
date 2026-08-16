# OpenClaw (Milo) on Termux - parallel instance

- Profile: `openclaw --profile termux` (state `~/.openclaw-termux`).
- Port: 18790 (loopback); canvas + browser ctrl on same port; 18792 browser.
- Start: `openclaw --profile termux gateway --port 18790`
- Watchdog: `~/.termux/watch-openclaw.sh`, cron 1-min via `tb exec` (proot).
- Config: WhatsApp ENABLED 2026-08-16 (`channels.whatsapp.enabled=true`,
  `plugins.entries.whatsapp.enabled=true`). `dmPolicy=pairing`,
  `groupPolicy=open` until real allowlist IDs are supplied.
- Baileys pinned to 7.0.0-rc12 (fixes GHSA-qvv5-jq5g-4cgg): global install +
  nested `node_modules/@whiskeysockets/baileys` replaced. After ANY openclaw
  update re-apply: `bash ~/.termux/re-pin-baileys.sh` (repo: scripts/).
- Linking (user step, QR): `openclaw --profile termux channels login
  --channel whatsapp`, scan the "Link a device" QR with the WhatsApp phone;
  on the same handset use "Link with phone number instead" (code entry).
  Verify: `openclaw --profile termux channels status --probe` -> "linked".
- PROOT conflict: proot Milo still WhatsApp-enabled on baileys rc.9. One
  WhatsApp number = one active session. Pin proot Milo to rc12 or disable
  its WhatsApp BEFORE linking this Termux instance.
- Secrets (gateway token, credentials) live only on-device; never in git.
- Cut-over from proot instance TBD (who owns which channel/port) - proot Milo
  stays authoritative for now.
