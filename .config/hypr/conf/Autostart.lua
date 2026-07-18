-- Autostart commands converted from exec-once entries.
hl.on("hyprland.start", function()
    -- KDE background services.
    hl.exec_cmd("kdeinit5")
    hl.exec_cmd("kded5")
    hl.exec_cmd("kiod5")

    -- Policy agent and keyring.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --daemonize --components=secrets,pkcs11,ssh,gpg")

    -- Removable media and status notifier fallback support.
    hl.exec_cmd("udiskie --automount --notify --no-tray --file-manager=nemo")
    hl.exec_cmd("bash -lc '$HOME/.config/hypr/scripts/status-notifier-fallback.sh'")

    -- Wallpaper and notifications.
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("swaync")

    -- Clipboard services.
    hl.exec_cmd("copyq --start-server")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Launch Firefox on workspace 1.
    hl.exec_cmd("firefox", { workspace = "1" })
end)
