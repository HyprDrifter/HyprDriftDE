#!/usr/bin/env bash
set -u

# Keep one XEmbed-to-SNI bridge available for legacy tray applications.
if command -v xembedsniproxy >/dev/null 2>&1 \
    && ! pgrep -u "$(id -u)" -x xembedsniproxy >/dev/null 2>&1; then
    /usr/bin/xembedsniproxy &
fi

# Quickshell v0.3 provides the native StatusNotifier watcher. Give it time to
# register before falling back to snixembed, which owns the same D-Bus name.
for ((attempt = 0; attempt < 40; attempt++)); do
    if busctl --user --quiet get-property \
        org.kde.StatusNotifierWatcher \
        /StatusNotifierWatcher \
        org.kde.StatusNotifierWatcher \
        ProtocolVersion >/dev/null 2>&1; then
        echo "[StatusNotifierFallback] Native watcher detected; snixembed not started."
        exit 0
    fi

    sleep 0.25
done

if command -v snixembed >/dev/null 2>&1; then
    echo "[StatusNotifierFallback] No native watcher detected; starting snixembed."
    exec snixembed
fi

echo "[StatusNotifierFallback] No StatusNotifier fallback is installed." >&2
exit 1
