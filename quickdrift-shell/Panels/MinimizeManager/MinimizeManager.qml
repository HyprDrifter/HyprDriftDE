pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Internal
import qs.Modules.Interactive
import qs.Services

Singleton {
    id: root

    property ListModel minimizedWindows: minimizedWindowList
    property int minmimizedWindowCount: minimizedWindows.count
    property bool operationInProgress: false
    property var focusedWindow: null
    property Toplevel activeToplevel: ToplevelManager.activeToplevel

    readonly property string minimizedWorkspaceName: "minimized"

    property string operationKind: ""
    property var pendingWindow: null
    property var pendingToplevel: null
    property string pendingAddress: ""
    property bool pendingPreviewCaptured: false
    property int pendingRestoreWorkspaceId: -1

    property bool previewDirectoryReady: false
    property bool previewDirectorySetupInProgress: false
    property bool previewCleanupInProgress: false
    property bool minimizeWaitingForPreviewSetup: false
    property var stalePreviewPaths: []

    ListModel {
        id: minimizedWindowList
    }

    function isValidAddress(address) {
        return typeof address === "string" && /^0x[0-9a-fA-F]+$/.test(address)
    }

    function previewPath(address) {
        if (!isValidAddress(address))
            return ""

        return Settings.minimizerWindowPreviewDirectory + "/" + address + ".png"
    }

    function geometryForWindow(windowInfo) {
        if (!windowInfo || !windowInfo.at || !windowInfo.size
                || windowInfo.at.length < 2 || windowInfo.size.length < 2)
            return ""

        const x = Number(windowInfo.at[0])
        const y = Number(windowInfo.at[1])
        const width = Number(windowInfo.size[0])
        const height = Number(windowInfo.size[1])

        if (!Number.isFinite(x) || !Number.isFinite(y)
                || !Number.isFinite(width) || !Number.isFinite(height)
                || width <= 0 || height <= 0)
            return ""

        return Math.round(x) + "," + Math.round(y) + " "
            + Math.round(width) + "x" + Math.round(height)
    }

    function minimizedWindowIndex(address) {
        for (let index = 0; index < minimizedWindows.count; ++index) {
            if (minimizedWindows.get(index).address === address)
                return index
        }

        return -1
    }

    function resetPendingOperation() {
        operationInProgress = false
        operationKind = ""
        minimizeWaitingForPreviewSetup = false
        pendingWindow = null
        pendingToplevel = null
        pendingAddress = ""
        pendingPreviewCaptured = false
        pendingRestoreWorkspaceId = -1
    }

    function minimizeFocusedWindow() {
        if (operationInProgress) {
            console.warn("A minimize or restore operation is already in progress")
            return
        }

        operationInProgress = true
        operationKind = "minimize"
        minimizeWaitingForPreviewSetup = true
        beginMinimizeWhenPreviewSetupFinishes()
    }

    function beginMinimizeWhenPreviewSetupFinishes() {
        if (previewDirectorySetupInProgress || previewCleanupInProgress)
            return

        if (!previewDirectoryReady) {
            ensurePreviewDirectory()
            return
        }

        minimizeWaitingForPreviewSetup = false
        activeWindowQuery.begin()
    }

    function ensurePreviewDirectory() {
        if (previewDirectorySetupInProgress)
            return

        previewDirectorySetupInProgress = true
        createPreviewDirectory.running = true
    }

    function finishPreviewDirectorySetup(success) {
        previewDirectorySetupInProgress = false
        previewDirectoryReady = success

        if (!success) {
            if (minimizeWaitingForPreviewSetup) {
                minimizeWaitingForPreviewSetup = false
                activeWindowQuery.begin()
            }
            return
        }

        if (success && !previewCleanupInProgress) {
            previewCleanupInProgress = true
            stalePreviewScan.begin()
            return
        }

        if (minimizeWaitingForPreviewSetup)
            beginMinimizeWhenPreviewSetupFinishes()
    }

    function handleActiveWindowResult(exitCode, output) {
        if (!operationInProgress || operationKind !== "minimize")
            return

        if (exitCode !== 0) {
            console.warn("Unable to query the active Hyprland window (exit code " + exitCode + ")")
            resetPendingOperation()
            return
        }

        let windowInfo = null
        try {
            windowInfo = JSON.parse(output)
        } catch (error) {
            console.warn("Unable to parse active Hyprland window data:", error)
            resetPendingOperation()
            return
        }

        const address = windowInfo ? windowInfo.address : ""
        const geometry = geometryForWindow(windowInfo)
        const workspaceName = windowInfo && windowInfo.workspace
            ? windowInfo.workspace.name
            : ""

        if (!isValidAddress(address) || geometry === "") {
            console.warn("Refusing to minimize a window with an invalid address or geometry")
            resetPendingOperation()
            return
        }

        if (workspaceName === "special:" + minimizedWorkspaceName) {
            console.warn("Window is already on special:" + minimizedWorkspaceName)
            resetPendingOperation()
            return
        }

        if (minimizedWindowIndex(address) !== -1) {
            console.warn("Window is already present in the minimized-window model:", address)
            resetPendingOperation()
            return
        }

        focusedWindow = windowInfo
        pendingWindow = windowInfo
        pendingToplevel = activeToplevel
        pendingAddress = address
        pendingPreviewCaptured = false

        if (previewDirectoryReady) {
            capturePreview.command = [
                "grim",
                "-g", geometry,
                previewPath(address)
            ]
            capturePreview.running = true
        } else {
            console.warn("Preview directory is unavailable; minimizing without a static preview")
            movePendingWindowToMinimizedWorkspace()
        }
    }

    function movePendingWindowToMinimizedWorkspace() {
        if (!isValidAddress(pendingAddress)) {
            console.warn("Refusing to move a window with an invalid address")
            resetPendingOperation()
            return
        }

        const dispatcher = "hl.dsp.window.move({ workspace = \"special:"
            + minimizedWorkspaceName + "\", window = \"address:"
            + pendingAddress + "\", follow = false })"

        moveToMinimizedWorkspace.exec([
            "hyprctl",
            "dispatch",
            dispatcher
        ])
    }

    function failPendingMinimize(message) {
        console.warn(message)

        if (pendingPreviewCaptured) {
            deletePreview.purpose = "failed-minimize"
            deletePreview.command = ["rm", "-f", "--", previewPath(pendingAddress)]
            deletePreview.running = true
        } else {
            resetPendingOperation()
        }
    }

    function handleMoveVerification(exitCode, output) {
        if (!operationInProgress || operationKind !== "minimize")
            return

        if (exitCode !== 0) {
            failPendingMinimize("Unable to verify the minimized window (exit code "
                + exitCode + ")")
            return
        }

        let clients = null
        try {
            clients = JSON.parse(output)
        } catch (error) {
            failPendingMinimize("Unable to parse Hyprland client data after minimizing: " + error)
            return
        }

        const client = Array.isArray(clients)
            ? clients.find(entry => entry && entry.address === pendingAddress)
            : null
        const workspaceName = client && client.workspace ? client.workspace.name : ""

        if (workspaceName !== "special:" + minimizedWorkspaceName) {
            failPendingMinimize("Hyprland reported success, but the window did not move to special:"
                + minimizedWorkspaceName)
            return
        }

        minimizedWindows.append({
            address: pendingAddress,
            title: pendingWindow.title || pendingWindow.class || "Window",
            topLevel: pendingToplevel
        })

        if (Settings.minimizerPlayAudioOnMinimize)
            AudioPlayback.play(Settings.minimizerPlayOnMinimizeSound)

        resetPendingOperation()
    }

    function restoreWindow(address) {
        const normalizedAddress = typeof address === "string" ? address.trim() : ""
        const modelIndex = minimizedWindowIndex(normalizedAddress)
        const workspace = Hyprland.focusedWorkspace
        const workspaceId = workspace ? Number(workspace.id) : NaN

        if (operationInProgress) {
            console.warn("A minimize or restore operation is already in progress")
            return
        }

        if (!isValidAddress(normalizedAddress) || modelIndex < 0
                || !Number.isInteger(workspaceId) || workspaceId < 1
                || workspaceId > 2147483647) {
            console.warn("Refusing to restore a window with invalid state:", normalizedAddress)
            return
        }

        operationInProgress = true
        operationKind = "restore"
        pendingAddress = normalizedAddress
        pendingRestoreWorkspaceId = workspaceId
        const dispatcher = "hl.dsp.window.move({ workspace = " + workspaceId
            + ", window = \"address:" + normalizedAddress
            + "\", follow = true })"
        restoreSelected.command = [
            "hyprctl",
            "dispatch",
            dispatcher
        ]
        restoreSelected.running = true
    }

    function handleRestoreVerification(exitCode, output) {
        if (!operationInProgress || operationKind !== "restore")
            return

        if (exitCode !== 0) {
            console.warn("Unable to verify the restored window (exit code " + exitCode + ")")
            resetPendingOperation()
            return
        }

        let clients = null
        try {
            clients = JSON.parse(output)
        } catch (error) {
            console.warn("Unable to parse Hyprland client data after restoring:", error)
            resetPendingOperation()
            return
        }

        const client = Array.isArray(clients)
            ? clients.find(entry => entry && entry.address === pendingAddress)
            : null
        const workspaceId = client && client.workspace
            ? Number(client.workspace.id)
            : NaN

        if (workspaceId !== pendingRestoreWorkspaceId) {
            console.warn("Hyprland reported success, but the window was not restored to workspace "
                + pendingRestoreWorkspaceId)
            resetPendingOperation()
            return
        }

        const modelIndex = minimizedWindowIndex(pendingAddress)
        if (modelIndex >= 0)
            minimizedWindows.remove(modelIndex, 1)

        deletePreview.purpose = "restore"
        deletePreview.command = ["rm", "-f", "--", previewPath(pendingAddress)]
        deletePreview.running = true
    }

    function restoreSelectedFunction(address) {
        restoreWindow(address)
    }

    function removeNextStalePreview() {
        if (stalePreviewPaths.length === 0) {
            previewCleanupInProgress = false

            if (minimizeWaitingForPreviewSetup)
                beginMinimizeWhenPreviewSetupFinishes()
            return
        }

        const path = stalePreviewPaths[0]
        stalePreviewPaths = stalePreviewPaths.slice(1)
        removeStalePreview.command = ["rm", "-f", "--", path]
        removeStalePreview.running = true
    }

    Component.onCompleted: ensurePreviewDirectory()

    Process {
        id: createPreviewDirectory
        command: ["mkdir", "-p", "--", Settings.minimizerWindowPreviewDirectory]

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Unable to create the minimize preview directory (exit code "
                    + exitCode + ", status " + exitStatus + ")")
                root.finishPreviewDirectorySetup(false)
                return
            }

            securePreviewDirectory.running = true
        }
    }

    Process {
        id: securePreviewDirectory
        command: ["chmod", "0700", Settings.minimizerWindowPreviewDirectory]

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Unable to secure the minimize preview directory (exit code "
                    + exitCode + ", status " + exitStatus + ")")

            root.finishPreviewDirectorySetup(exitCode === 0)
        }
    }

    Process {
        id: stalePreviewScan
        property string output: ""
        property bool outputReady: false
        property bool exitReceived: false
        property bool handled: false
        property int completedExitCode: -1

        command: [
            "find", "--", Settings.minimizerWindowPreviewDirectory,
            "-maxdepth", "1",
            "-type", "f",
            "-name", "0x*.png",
            "-print"
        ]

        function begin() {
            output = ""
            outputReady = false
            exitReceived = false
            handled = false
            completedExitCode = -1
            running = true
        }

        function finishIfReady() {
            if (handled || !outputReady || !exitReceived)
                return

            handled = true

            if (completedExitCode !== 0) {
                console.warn("Unable to scan stale minimize previews (exit code "
                    + completedExitCode + ")")
                root.stalePreviewPaths = []
                root.removeNextStalePreview()
                return
            }

            const directoryPrefix = Settings.minimizerWindowPreviewDirectory + "/"
            root.stalePreviewPaths = output.split("\n").filter(path => {
                if (!path.startsWith(directoryPrefix))
                    return false

                const filename = path.slice(directoryPrefix.length)
                return /^0x[0-9a-fA-F]+[.]png$/.test(filename)
            })
            root.removeNextStalePreview()
        }

        onExited: (exitCode, exitStatus) => {
            completedExitCode = exitCode
            exitReceived = true
            finishIfReady()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                stalePreviewScan.output = this.text
                stalePreviewScan.outputReady = true
                stalePreviewScan.finishIfReady()
            }
        }
    }

    Process {
        id: removeStalePreview

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Unable to remove a stale minimize preview (exit code "
                    + exitCode + ", status " + exitStatus + ")")

            root.removeNextStalePreview()
        }
    }

    Process {
        id: activeWindowQuery
        property string output: ""
        property bool outputReady: false
        property bool exitReceived: false
        property bool handled: false
        property int completedExitCode: -1

        command: ["hyprctl", "activewindow", "-j"]

        function begin() {
            output = ""
            outputReady = false
            exitReceived = false
            handled = false
            completedExitCode = -1
            running = true
        }

        function finishIfReady() {
            if (handled || !outputReady || !exitReceived)
                return

            handled = true
            root.handleActiveWindowResult(completedExitCode, output)
        }

        onExited: (exitCode, exitStatus) => {
            completedExitCode = exitCode
            exitReceived = true
            finishIfReady()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                activeWindowQuery.output = this.text
                activeWindowQuery.outputReady = true
                activeWindowQuery.finishIfReady()
            }
        }
    }

    Process {
        id: capturePreview

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Static minimize preview capture failed; continuing without it "
                    + "(exit code " + exitCode + ", status " + exitStatus + ")")
            } else {
                root.pendingPreviewCaptured = true
            }

            root.movePendingWindowToMinimizedWorkspace()
        }
    }

    Process {
        id: moveToMinimizedWorkspace

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.failPendingMinimize("Unable to move the window to the minimized workspace "
                    + "(exit code " + exitCode + ", status " + exitStatus + ")")
                return
            }

            verifyMinimizedWindow.begin()
        }
    }

    Process {
        id: verifyMinimizedWindow
        property string output: ""
        property bool outputReady: false
        property bool exitReceived: false
        property bool handled: false
        property int completedExitCode: -1

        command: ["hyprctl", "clients", "-j"]

        function begin() {
            output = ""
            outputReady = false
            exitReceived = false
            handled = false
            completedExitCode = -1
            running = true
        }

        function finishIfReady() {
            if (handled || !outputReady || !exitReceived)
                return

            handled = true
            root.handleMoveVerification(completedExitCode, output)
        }

        onExited: (exitCode, exitStatus) => {
            completedExitCode = exitCode
            exitReceived = true
            finishIfReady()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                verifyMinimizedWindow.output = this.text
                verifyMinimizedWindow.outputReady = true
                verifyMinimizedWindow.finishIfReady()
            }
        }
    }

    Process {
        id: restoreSelected

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("Unable to restore the minimized window (exit code "
                    + exitCode + ", status " + exitStatus + ")")
                root.resetPendingOperation()
                return
            }

            verifyRestoredWindow.begin()
        }
    }

    Process {
        id: verifyRestoredWindow
        property string output: ""
        property bool outputReady: false
        property bool exitReceived: false
        property bool handled: false
        property int completedExitCode: -1

        command: ["hyprctl", "clients", "-j"]

        function begin() {
            output = ""
            outputReady = false
            exitReceived = false
            handled = false
            completedExitCode = -1
            running = true
        }

        function finishIfReady() {
            if (handled || !outputReady || !exitReceived)
                return

            handled = true
            root.handleRestoreVerification(completedExitCode, output)
        }

        onExited: (exitCode, exitStatus) => {
            completedExitCode = exitCode
            exitReceived = true
            finishIfReady()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                verifyRestoredWindow.output = this.text
                verifyRestoredWindow.outputReady = true
                verifyRestoredWindow.finishIfReady()
            }
        }
    }

    Process {
        id: deletePreview
        property string purpose: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Unable to remove a minimize preview (exit code "
                    + exitCode + ", status " + exitStatus + ")")

            if (purpose === "restore") {
                if (Settings.minimizerPlayAudioOnRestore)
                    AudioPlayback.play(Settings.minimizerPlayOnRestoreSound)

                GlobalVariables.minimizeManagerVisible = false
            }

            purpose = ""
            root.resetPendingOperation()
        }
    }
}
