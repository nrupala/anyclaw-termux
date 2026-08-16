#!/data/data/com.termux/files/usr/bin/bash
# Hold a CPU wake lock + ongoing notification so Termux survives screen-off/Doze.
# Requires Termux:API installed. Termux:Boot runs every *.sh in ~/.termux/boot/.
termux-wake-lock
pgrep -x sshd >/dev/null || sshd
