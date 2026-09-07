pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "QuickActionsData.js" as QuickActionsData

Singleton {
    id: root

    readonly property int schemaVersion: QuickActionsData.schemaVersion
    property var actions: []
    property bool ready: false
    property int revision: 0
    property int idSerial: 0
    property string persistedPayload: ""
    property string pendingPayload: ""
    property string currentWritePayload: ""
    property bool writeInProgress: false
    property bool warningLogged: false

    function warnOnce(message): void {
        if (warningLogged)
            return
        warningLogged = true
        console.warn("Quick actions:", message)
    }

    function load(): void {
        let contents = ""
        try {
            contents = stateFile.text()
        } catch (error) {
            contents = ""
        }

        const decoded = QuickActionsData.decode(contents)
        if (!decoded.valid && contents.trim().length > 0)
            warnOnce("invalid or unsupported saved data was ignored")

        actions = decoded.actions
        persistedPayload = decoded.valid && contents.trim().length > 0
            ? QuickActionsData.encode(decoded.actions)
            : ""
        ready = true
        revision += 1
    }

    function replaceActions(nextActions): void {
        const nextPayload = QuickActionsData.encode(nextActions)
        if (nextPayload === QuickActionsData.encode(actions))
            return

        actions = nextActions
        revision += 1
        pendingPayload = nextPayload
        if (!writeInProgress)
            saveTimer.restart()
    }

    function addAction(label, icon, command): bool {
        const id = QuickActionsData.uniqueId(
            actions, Date.now(), ++idSerial)
        const next = QuickActionsData.addAction(actions, {
            id: id,
            label: label,
            icon: icon,
            command: command
        })
        if (next.length === actions.length)
            return false

        replaceActions(next)
        return true
    }

    function updateAction(id, label, icon, command): bool {
        const existing = QuickActionsData.findAction(actions, id)
        if (!existing)
            return false

        const next = QuickActionsData.updateAction(
            actions, id, label, icon, command)
        if (QuickActionsData.encode(next)
                === QuickActionsData.encode(actions))
            return false

        replaceActions(next)
        return true
    }

    function removeAction(id): bool {
        const next = QuickActionsData.removeAction(actions, id)
        if (next.length === actions.length)
            return false

        replaceActions(next)
        return true
    }

    function moveAction(id, targetIndex): bool {
        const next = QuickActionsData.moveAction(actions, id, targetIndex)
        if (QuickActionsData.encode(next)
                === QuickActionsData.encode(actions))
            return false

        replaceActions(next)
        return true
    }

    function runAction(id, completionPath): bool {
        const action = QuickActionsData.findAction(actions, id)
        if (!action)
            return false

        const requestedCompletionPath = String(completionPath || "").trim()
        const launchCommand = requestedCompletionPath.length > 0
            ? QuickActionsData.buildTrackedLaunchCommand(
                action.command, requestedCompletionPath)
            : QuickActionsData.buildLaunchCommand(action.command)
        if (launchCommand.length === 0)
            return false

        Quickshell.execDetached(launchCommand)
        return true
    }

    function iconSource(action): string {
        const icon = String(action?.icon || "").trim()
        if (icon.length === 0)
            return ""
        return Quickshell.iconPath(icon, true)
    }

    function writePending(): void {
        if (writeInProgress || pendingPayload.length === 0
                || pendingPayload === persistedPayload)
            return

        currentWritePayload = pendingPayload
        pendingPayload = ""
        writeInProgress = true
        stateFile.setText(currentWritePayload)
    }

    Component.onCompleted: load()

    Timer {
        id: saveTimer
        interval: 180
        repeat: false
        onTriggered: root.writePending()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("quick-actions-v1.json")
        blockLoading: true
        blockWrites: false
        atomicWrites: true
        printErrors: false

        onSaved: {
            root.persistedPayload = root.currentWritePayload
            root.currentWritePayload = ""
            root.writeInProgress = false
            if (root.pendingPayload.length > 0
                    && root.pendingPayload !== root.persistedPayload)
                saveTimer.restart()
        }

        onSaveFailed: error => {
            root.currentWritePayload = ""
            root.writeInProgress = false
            root.pendingPayload = QuickActionsData.encode(root.actions)
            root.warnOnce("saved data could not be written; continuing in memory")
        }
    }
}
