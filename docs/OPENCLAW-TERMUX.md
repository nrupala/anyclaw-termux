# OpenClaw (Milo) on Termux - parallel instance

- Profile: `openclaw --profile termux` (state `~/.openclaw-termux`).
- Port: 18790 (loopback); canvas + browser ctrl on same port; 18792 browser.
- Start: `openclaw --profile termux gateway --port 18790`
- Watchdog: `~/.termux/watch-openclaw.sh`, cron 1-min via `tb exec` (proot).
- Config: WhatsApp channels disabled (plugins.entries.whatsapp.enabled=false +
  channels.whatsapp.enabled=false). Baileys rc.9 present but inert.
- Enable WhatsApp LATER (on WiFi): pin `@whiskeysockets/baileys@7.0.0-rc12+`
  via npm override in a local openclaw install, then flip config flags.
- Secrets (gateway token, credentials) live only on-device; never in git.
- Cut-over from proot instance TBD (who owns which channel/port) - proot Milo
  stays authoritative for now.
