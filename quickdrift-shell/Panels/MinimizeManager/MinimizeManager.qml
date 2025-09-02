pragma Singleton

// ────── Imports ──────
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Modules/Interactive"
import "Modules/Interactive/ApplicationLauncher"
import "Internal"
import "Services"

Singleton {
    id: root

    // ────── Models ──────
    property ListModel minimizedWindows : minWinList

    ListModel {
        id: minWinList
    }


    // ────── Dynamic State ──────
    property var     focusedWindow
    property int     minmimizedWindowCount              : root.minimizedWindows.count
    property bool    imageExist                         : false
    property Toplevel activeToplevel                    : ToplevelManager.activeToplevel
    readonly property string minimizedWorkspaceName     : "minimized"

    // ────── Functions ──────
    function minimizeFocusedWindow() {
        getFocusedWindow.running = true
        console.log("Woulda minimized")
        //console.log(`${activeToplevel.appId}`)
        //minimizeWithID.running = true
        if(Settings.minimizerPlayAudioOnMinimize)
        {
            AudioPlayback.play(Settings.minimizerPlayOnMinimizeSound)
        }
    }

    function getAppImage() {
        const info = root.focusedWindow
        console.log("INSIDE GET APP IAMGE")
        var geometry = `${info.at[0]},${info.at[1]} ${info.size[0]}x${info.size[1]}`
        console.log(`Geometry : ${geometry}`)
        captureImage.command = ["bash", "-c", `grim -g "${geometry}" ${Settings.minimizerWindowPreviewDirectory}/${info.address}.png`]
        captureImage.running = true
        console.log("AFter hyprland displatch")
    }

    function restoreSelectedFunction(id) {
        // Move window with given ID back to focused workspace
        restoreSelected.command = ["bash", "-c", `hyprctl dispatch movetoworkspace ${Hyprland.focusedWorkspace.id}, address:${id}`]
        restoreSelected.address = id
        restoreSelected.running = true
        if(Settings.minimizerPlayAudioOnRestore)
        {
            AudioPlayback.play(Settings.minimizerPlayOnRestoreSound)
        }
    }

    // ────── Processes ──────

    // 🧠 Get info on currently focused window using hyprctl, then dispatch minimize and screenshot
    Process {
        id: getFocusedWindow
        command: ["bash", "-c", "hyprctl activewindow -j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: { 
                root.focusedWindow = JSON.parse(this.text)
                console.log("toplevel :  " + root.activeToplevel)
                root.focusedWindow.topLevel = root.activeToplevel
                root.getAppImage()

                console.log("done appending")
                minimizeWithID.command = ["bash", "-c", `hyprctl dispatch movetoworkspacesilent special:${root.minimizedWorkspaceName},address:${root.focusedWindow.address}`]
                minimizeWithID.running = true
            }
        }
    }

    // 📸 Take a screenshot of the focused window using grim, then add to minimized list
    Process {
        id: captureImage
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Stream Finished")
                console.log(this.text)
                root.minimizedWindows.append(root.focusedWindow)
            }
        }
    }

    // 🎯 Move the currently selected window to the special "minimized" workspace
    Process {
        id: minimizeWithID
        command: []
        running: false
    }

    // 🧼 Restore a window from minimized state and delete its preview image
    Process {
        id: restoreSelected
        property string address: ""
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("removing")
                Hyprland.dispatch(`exec rm -r /tmp/SlightlyBetterDesktop/Minimizer/Previews/${restoreSelected.address}.png`)
                console.log("After removing")
            }
        }
    }

    // 📁 Ensure temp preview directory exists, then wipe it clean
    Process {
        id: verifyTmpDir
        command: ["mkdir", "-p", `${Settings.minimizerWindowPreviewDirectory}`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                Hyprland.dispatch(`exec rm -r /tmp/SlightlyBetterDesktop/Minimizer/Previews/*`)
            }
        }
    }
}
