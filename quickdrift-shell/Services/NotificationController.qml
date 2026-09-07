pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int count: 0
    property bool doNotDisturb: false
    property bool controlCenterVisible: false
    property bool inhibited: false
    property bool available: false
    property bool focusDismissArmed: false
    property int hoverButtonX: 0
    property int hoverButtonY: 0
    property int hoverButtonWidth: 0
    property int hoverButtonHeight: 0

    function updateState(line): void {
        const value = String(line).trim()
        if (value.length === 0)
            return

        try {
            const state = JSON.parse(value)
            count = Math.max(0, Number(state.count) || 0)
            doNotDisturb = state.dnd === true
            controlCenterVisible = state.visible === true
            inhibited = state.inhibited === true
            available = true
        } catch (error) {
            console.warn("Could not parse swaync state:", error)
        }
    }

    function toggleControlCenter(buttonCenterX, outputWidth,
            buttonX, buttonY, buttonWidth, buttonHeight): void {
        hoverButtonX = Math.round(Number(buttonX))
        hoverButtonY = Math.round(Number(buttonY))
        hoverButtonWidth = Math.max(1, Math.round(Number(buttonWidth)))
        hoverButtonHeight = Math.max(1, Math.round(Number(buttonHeight)))

        if (controlCenterVisible)
            hoverWatcher.running = false

        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/hypr/scripts/toggle-swaync.sh",
            String(Math.round(Number(buttonCenterX))),
            String(Math.round(Number(outputWidth)))
        ])
    }

    function startHoverWatcher(): void {
        if (!controlCenterVisible || hoverButtonWidth <= 0
                || hoverButtonHeight <= 0)
            return

        hoverWatcher.command = [
            "/usr/bin/bash",
            Quickshell.env("HOME")
                + "/.config/hypr/scripts/watch-swaync-hover.sh",
            String(hoverButtonX),
            String(hoverButtonY),
            String(hoverButtonWidth),
            String(hoverButtonHeight)
        ]
        hoverWatcher.running = true
    }

    function closeControlCenter(): void {
        focusDismissArmed = false
        Quickshell.execDetached([
            "/usr/bin/swaync-client",
            "--close-panel",
            "--skip-wait"
        ])
    }

    function handleHyprlandEvent(event): void {
        if (!controlCenterVisible || !focusDismissArmed || !event)
            return

        const name = String(event.name || "")
        const toplevelFocusChanged = name === "activewindow"
            || name === "activewindowv2"
        const outputFocusChanged = name === "focusedmon"
            || name === "workspace"
            || name === "workspacev2"

        // SwayNC creates and rearranges auxiliary surfaces for notification
        // controls and grouped cards. An openlayer event therefore does not
        // reliably mean the user left the notification center. Pointer loss
        // is handled by the hover watcher instead.
        if (toplevelFocusChanged || outputFocusChanged)
            closeControlCenter()
    }

    function clearAll(): void {
        Quickshell.execDetached([
            "/usr/bin/swaync-client",
            "--close-all",
            "--skip-wait"
        ])
    }

    onControlCenterVisibleChanged: {
        if (controlCenterVisible) {
            focusDismissTimer.restart()
            Qt.callLater(startHoverWatcher)
        } else {
            focusDismissTimer.stop()
            focusDismissArmed = false
            hoverWatcher.running = false
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            root.handleHyprlandEvent(event)
        }
    }

    Process {
        id: subscription

        running: true
        command: [
            "/usr/bin/swaync-client",
            "--subscribe"
        ]

        stdout: SplitParser {
            onRead: data => root.updateState(data)
        }

        stderr: SplitParser {}

        onExited: (exitCode, exitStatus) => {
            root.available = false
            restartTimer.restart()
        }
    }

    Process {
        id: hoverWatcher
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: subscription.running = true
    }

    Timer {
        id: focusDismissTimer

        interval: 150
        repeat: false
        onTriggered: root.focusDismissArmed = root.controlCenterVisible
    }
}
