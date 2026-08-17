#!/data/data/com.termux/files/usr/bin/bash
# Local agent + Maven chat engine (llama.cpp, Termux, Vulkan GPU).
# Serves OpenAI-compatible http://127.0.0.1:9090/v1 for codex/opencode/openclaw
# AND Maven chat on 9090. One engine at a time, lowest-power model by default.
# Usage: AGENT_MODEL=phi-4-mini|qwen3-4b  bash agent-engine.sh start|stop|status
set -u
BIN=$HOME/llama.cpp/build/bin/llama-server
STATE=$HOME/state
LOG=$HOME/logs
PIDF=$STATE/chat-gpu.pid
PORT=9090
mkdir -p "$STATE" "$LOG"
: "${AGENT_MODEL:=phi-4-mini}"
case "$AGENT_MODEL" in
  phi-4-mini) MODEL=$HOME/models/phi-4-mini-instruct-q4_k_m.gguf;      CTX=8192 ;;
  qwen3-4b)   MODEL=/sdcard/Download/models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf; CTX=16384 ;;
  *) echo "unknown AGENT_MODEL=$AGENT_MODEL (choose: phi-4-mini|qwen3-4b)" >&2; exit 2 ;;
esac

max_zone() { local m=0 t; for z in /sys/class/thermal/thermal_zone*/temp; do t=$(cat "$z" 2>/dev/null); [ "${t:-0}" -gt "$m" ] && m=$t; done; echo $((m/1000)); }
running() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

status() {
  if running; then
    echo "agent engine UP on 127.0.0.1:${PORT} (pid $(cat "$PIDF"), model=${AGENT_MODEL:-phi-4-mini})"
    curl -s -m 5 "http://127.0.0.1:${PORT}/v1/models" | head -c 200; echo
  else
    echo "agent engine DOWN (start: AGENT_MODEL=phi-4-mini|qwen3-4b $0 start)"
  fi
}

start() {
  running && { echo "already running pid $(cat "$PIDF")"; return 0; }
  local heat; heat=$(max_zone)
  if [ "${heat:-0}" -ge 78 ]; then
    echo "heat guard: max zone ${heat}C >= 78 - not starting. Retry when cooler." >&2; return 6
  fi
  [ -f "$MODEL" ] || { echo "model missing: $MODEL" >&2; return 3; }
  export PATH=$PREFIX/bin:/system/bin:$PATH
  setsid nohup "$BIN" -m "$MODEL" --host 127.0.0.1 --port "$PORT" -c "$CTX" \
    --flash-attn on --parallel 1 -ngl 24 -t 4 --tools get_datetime,get_info \
    > "$LOG/chat-gpu.log" 2>&1 < /dev/null &
  echo $! > "$PIDF"
  sleep 2
  if kill -0 "$(cat "$PIDF")" 2>/dev/null; then
    echo "started model=${AGENT_MODEL} on 127.0.0.1:${PORT} (ctx ${CTX})"
    curl -s -m 5 "http://127.0.0.1:${PORT}/v1/models" | head -c 200; echo
  else
    echo "failed to stay up - check $LOG/chat-gpu.log" >&2; rm -f "$PIDF"; return 1
  fi
}

stop() {
  if running; then
    local pid; pid=$(cat "$PIDF")
    kill "$pid" 2>/dev/null; sleep 1
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
  fi
  rm -f "$PIDF"
  echo "agent engine stopped"
}

case "${1:-status}" in
  start) start ;;
  stop)  stop ;;
  status) status ;;
  *) echo "usage: $0 start|stop|status (env AGENT_MODEL=phi-4-mini|qwen3-4b)" >&2; exit 1 ;;
esac
