# Maven -> Termux GPU wiring (prep; NOT activated)

Maven gateway (9095) always targets 127.0.0.1:9090 (chat) / 9096 (embed).
Delegation = run GPU servers in Termux + marker files, so launcher skips local CPU engines.

1. In Termux: `bash /sdcard/Download/termux-bridge/termux-llama-server.sh` (serves 9090/9096 on loopback).
   Health: `curl -m 5 http://127.0.0.1:9090/v1/models`.
2. Markers (create only when Maven is resumed, after user lifts maintenance hold):
   `touch /root/maven/state/external-chat.json` and `external-embed.json`.
   Launcher + watchdog then skip starting local chat/embed engines.
3. Resume: `rm /root/maven/state/maintenance && bash /root/maven/launch-maven.sh`.
4. Rollback: remove markers, restart; proot CPU engines take back over.
Stable offload: -ngl 24 (full -ngl 999 crashes upstream; measured pp 11.75 / tg 7.50).
