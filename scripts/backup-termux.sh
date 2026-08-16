#!/data/data/com.termux/files/usr/bin/bash
# Daily backup of Termux home -> /sdcard/Download/backups/termux (survives AnyClaw reinstalls)
# Mirrors proot backup.sh conventions: timestamped tarball + state + components, prune old.
export PATH=$PREFIX/bin:/system/bin:$PATH
DEST=/sdcard/Download/backups/termux
STATE=$DEST/state
COMP=$DEST/components
mkdir -p "$STATE" "$COMP"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=$DEST/termux-home-$STAMP.tar.gz
TMP=$DEST/.tmp-$STAMP.tar.gz

tar -czf "$TMP" \
  --exclude='./.cache' --exclude='./.npm' --exclude='*/node_modules' \
  --exclude='./llama.cpp' --exclude='./.local/opencode' --exclude='./.bash_history' \
  --warning=no-file-changed -C "$HOME" . 2>/dev/null \
  && mv "$TMP" "$OUT" || { rm -f "$TMP"; echo "termux backup FAILED"; exit 1; }

dpkg -l > "$STATE/packages.txt" 2>/dev/null || true
pkg list-installed > "$STATE/pkg-list.txt" 2>/dev/null || true
cp -f "$HOME/.termux/start-sshd.sh" "$COMP/" 2>/dev/null || true
cp -f "$HOME/.termux/termux.properties" "$COMP/" 2>/dev/null || true
cp -f /sdcard/Download/termux-bridge/config.json "$COMP/" 2>/dev/null || true
cp -f /sdcard/Download/termux-bridge/authorized_keys "$COMP/" 2>/dev/null || true
cp -f /sdcard/Download/termux-bridge/build-vulkan.sh "$COMP/" 2>/dev/null || true
date -u +%Y-%m-%dT%H:%M:%SZ > "$STATE/last-backup.txt"
echo "termux backup ok: $OUT ($(du -h "$OUT" 2>/dev/null | cut -f1))"
ls -1t "$DEST"/termux-home-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
