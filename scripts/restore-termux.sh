#!/data/data/com.termux/files/usr/bin/bash
# Restore Termux home from latest backup. Run from Termux.
export PATH=$PREFIX/bin:/system/bin:$PATH
DEST=/sdcard/Download/backups/termux
LATEST=$(ls -1t "$DEST"/termux-home-*.tar.gz 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then echo "no termux backup found in $DEST"; exit 1; fi
echo "restoring from $LATEST"
tar -xzf "$LATEST" -C "$HOME" 2>/dev/null || true
echo "restore done. Verify:"
echo "  node --version && npm --version"
echo "  sshd (then from proot: tb status)"
echo "  vulkaninfo --summary"
echo "  bash ~/.termux/backup-termux.sh (confirm no FAILED)"
