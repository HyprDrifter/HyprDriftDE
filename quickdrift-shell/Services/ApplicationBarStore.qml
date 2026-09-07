pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "ApplicationBarData.js" as ApplicationBarData

Singleton {
    id: root

    readonly property int schemaVersion: ApplicationBarData.schemaVersion
    property var pinnedIds: []
    property bool ready: false
    property int revision: 0
    property string persistedPayload: ""
    property string pendingPayload: ""
    property string currentWritePayload: ""
    property bool writeInProgress: false
    property bool warningLogged: false

    function warnOnce(message): void {
        if (warningLogged)
            return
        warningLogged = true
        console.warn("Application bar:", message)
    }

    function load(): void {
        let contents = ""
        try {
            contents = stateFile.text()
        } catch (error) {
            contents = ""
        }

        const decoded = ApplicationBarData.decode(contents)
        if (!decoded.valid && contents.trim().length > 0)
            warnOnce("invalid or unsupported saved data was ignored")

        pinnedIds = decoded.pinnedIds
        persistedPayload = decoded.valid && contents.trim().length > 0
            ? ApplicationBarData.encode(decoded.pinnedIds)
            : ""
        ready = true
        revision += 1
        schedulePrune()
    }

    function replacePins(nextPins): void {
        const normalized = ApplicationBarData.normalizedPinnedIds(nextPins)
        const payload = ApplicationBarData.encode(normalized)
        if (payload === ApplicationBarData.encode(pinnedIds))
            return

        pinnedIds = normalized
        revision += 1
        pendingPayload = payload
        if (!writeInProgress)
            saveTimer.restart()
    }

    function isPinned(desktopId): bool {
        const currentRevision = revision
        return ApplicationBarData.isPinned(pinnedIds, desktopId)
    }

    function pin(desktopId): bool {
        const next = ApplicationBarData.pin(pinnedIds, desktopId)
        if (ApplicationBarData.encode(next)
                === ApplicationBarData.encode(pinnedIds))
            return false
        replacePins(next)
        return true
    }

    function unpin(desktopId): bool {
        const next = ApplicationBarData.unpin(pinnedIds, desktopId)
        if (next.length === pinnedIds.length)
            return false
        replacePins(next)
        return true
    }

    function movePin(desktopId, targetIndex): bool {
        const next = ApplicationBarData.movePin(
            pinnedIds, desktopId, targetIndex)
        if (ApplicationBarData.encode(next)
                === ApplicationBarData.encode(pinnedIds))
            return false
        replacePins(next)
        return true
    }

    function schedulePrune(): void {
        if (ready && ApplicationIndex.ready)
            pruneTimer.restart()
    }

    function pruneUnavailable(): void {
        if (!ApplicationIndex.ready || ApplicationIndex.entries.length === 0)
            return

        const availableIds = ApplicationIndex.entries.map(record => record.id)
        const next = ApplicationBarData.prunePins(pinnedIds, availableIds)
        if (next.length !== pinnedIds.length)
            replacePins(next)
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

    Connections {
        target: ApplicationIndex
        function onRevisionChanged(): void {
            root.schedulePrune()
        }
    }

    Timer {
        id: pruneTimer
        interval: 1000
        repeat: false
        onTriggered: root.pruneUnavailable()
    }

    Timer {
        id: saveTimer
        interval: 180
        repeat: false
        onTriggered: root.writePending()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("application-bar-v1.json")
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
            root.pendingPayload = ApplicationBarData.encode(root.pinnedIds)
            root.warnOnce("saved data could not be written; continuing in memory")
        }
    }
}
