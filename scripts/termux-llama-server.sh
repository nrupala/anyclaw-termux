#!/data/data/com.termux/files/usr/bin/bash
# Maven GPU engines in Termux (native Vulkan). Run via: bash scripts/termux-llama-server.sh
# Delegation: Maven gateway stays on 127.0.0.1:9095; these serve 9090 (chat) / 9096 (embed).
export PATH=$PREFIX/bin:/system/bin:$PATH
BIN=$HOME/llama.cpp/build/bin/llama-server
MODEL_CHAT=$HOME/models/phi-4-mini-instruct-q4_k_m.gguf
MODEL_EMBED=$HOME/models/nomic-embed-text-v1.5.Q4_K_M.gguf
PORT_CHAT=9090
PORT_EMBED=9096
# Stable offload: full -ngl 999 crashes (upstream Vulkan bug at high-ngl + long prompts);
# -ngl 24 measured: pp512 11.75 t/s, tg32 7.50 t/s (CPU baseline 4.98/2.32).
echo "starting chat GPU server on 127.0.0.1:${PORT_CHAT} (ngl=24, fa on, ctx 8192)"
setsid nohup "$BIN" -m "$MODEL_CHAT" --host 127.0.0.1 --port "$PORT_CHAT" \
  -c 8192 --flash-attn on --parallel 1 -ngl 24 -t 4 > "$HOME/logs/chat-gpu.log" 2>&1 < /dev/null &
echo $! > "$HOME/state/chat-gpu.pid"
sleep 2
echo "starting embed GPU server on 127.0.0.1:${PORT_EMBED} (ngl=24)"
[ -f "$MODEL_EMBED" ] || cp /sdcard/Download/models/nomic-embed-text-v1.5.Q4_K_M.gguf "$MODEL_EMBED"
setsid nohup "$BIN" -m "$MODEL_EMBED" --host 127.0.0.1 --port "$PORT_EMBED" \
  -c 4096 --embedding -ngl 24 -t 4 > "$HOME/logs/embed-gpu.log" 2>&1 < /dev/null &
echo $! > "$HOME/state/embed-gpu.pid"
echo "started. verify: curl -m 5 http://127.0.0.1:9090/v1/models"
