pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Configs
import qs.Configs.Settings
import qs.Modules.Services

Singleton {
    id: root

    // ────── Models ──────
    property ListModel minimizedWindows: minWinList

    ListModel {
        id: minWinList
    }

    // ────── Dynamic State ──────
    property var focusedWindow
    property int minimizedWindowCount: root.minimizedWindows.count
    property bool imageExist: false
    property Toplevel activeToplevel: ToplevelManager.activeToplevel
    readonly property string minimizedWorkspaceName: "minimized"

    // ────── Functions ──────
    function minimizeFocusedWindow() {
        getFocusedWindow.running = true
        console.log("Minimizing focused window")
        if (ThemeSettings.minimizerPlayAudioOnMinimize) {
            AudioPlayback.play(ThemeSettings.minimizerPlayOnMinimizeSound)
        }
    }

    function getAppImage() {
        const info = root.focusedWindow
        console.log("Capturing window preview")
        var geometry = `${info.at[0]},${info.at[1]} ${info.size[0]}x${info.size[1]}`
        captureImage.command = ["bash", "-c", `grim -g "${geometry}" ${ThemeSettings.minimizerWindowPreviewDirectory}/${info.address}.png`]
        captureImage.running = true
    }

    function restoreSelectedFunction(id) {
        restoreSelected.command = ["bash", "-c", `hyprctl dispatch movetoworkspace ${Hyprland.focusedWorkspace.id}, address:${id}`]
        restoreSelected.address = id
        restoreSelected.running = true
        if (ThemeSettings.minimizerPlayAudioOnRestore) {
            AudioPlayback.play(ThemeSettings.minimizerPlayOnRestoreSound)
        }
    }

    // ────── Processes ──────

    Process {
        id: getFocusedWindow
        command: ["bash", "-c", "hyprctl activewindow -j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.focusedWindow = JSON.parse(this.text)
                root.focusedWindow.topLevel = root.activeToplevel
                root.getAppImage()
                minimizeWithID.command = ["bash", "-c", `hyprctl dispatch movetoworkspacesilent special:${root.minimizedWorkspaceName},address:${root.focusedWindow.address}`]
                minimizeWithID.running = true
            }
        }
    }

    Process {
        id: captureImage
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.minimizedWindows.append(root.focusedWindow)
                captureImage.running = false
            }
        }
    }

    Process {
        id: minimizeWithID
        command: []
        running: false
    }

    Process {
        id: restoreSelected
        property string address: ""
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Removing window preview for: " + restoreSelected.address)
                Hyprland.dispatch(`exec rm -r ${ThemeSettings.minimizerWindowPreviewDirectory}/${restoreSelected.address}.png`)
            }
        }
    }

    Process {
        id: verifyTmpDir
        command: ["mkdir", "-p", `${ThemeSettings.minimizerWindowPreviewDirectory}`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                Hyprland.dispatch(`exec rm -r ${ThemeSettings.minimizerWindowPreviewDirectory}/*`)
            }
        }
    }
}
