#!/usr/bin/env bash

# Persistent Quickshell runner with timestamped logs

config="quickdrift-shell"
logDir="$HOME/.config/quickshell/quick-drift/Logs"

# Ensure log directory exists
mkdir -p "$logDir"

echo "[+] Launching Quickshell with config: $config"
echo "[+] Logs will be saved in: $logDir"

while true; do
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    logFile="$logDir/${timestamp}-qs.log"

    echo "[+] Starting Quickshell at $timestamp"
    echo "-------------------------------------" >> "$logFile"

    exec qs -p /etc/xdg/hyprdrift/quickdrift-shell/shell.qml --no-duplicate --log-times >> "$logFile" 2>&1

    echo "[!] Quickshell crashed or exited. Restarting in 1s..." | tee -a "$logFile"
    sleep 1
done
