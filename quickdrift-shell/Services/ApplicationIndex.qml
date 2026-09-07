pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "ApplicationSearch.js" as ApplicationSearch

Singleton {
    id: root

    readonly property int schemaVersion: ApplicationSearch.schemaVersion
    property var entries: []
    property var entriesById: ({})
    property bool ready: false
    property bool cacheLoaded: false
    property int revision: 0
    property string persistedPayload: ""
    property string pendingPayload: ""
    property string currentWritePayload: ""
    property bool writeInProgress: false
    property bool cacheWarningLogged: false

    function warnCache(message): void {
        if (cacheWarningLogged)
            return
        cacheWarningLogged = true
        console.warn("Application index cache:", message)
    }

    function rebuildLookup(records): void {
        const nextLookup = ({})
        for (const record of records)
            nextLookup["id:" + record.id] = record
        entriesById = nextLookup
    }

    function loadCache(): void {
        let contents = ""
        try {
            contents = cacheFile.text()
        } catch (error) {
            warnCache("could not be read; rebuilding from live entries")
        }

        const decoded = ApplicationSearch.decodeCache(contents)
        if (!decoded.valid && contents.trim().length > 0)
            warnCache("invalid or unsupported data was ignored")

        entries = decoded.entries
        rebuildLookup(entries)
        persistedPayload = decoded.valid && contents.trim().length > 0
            ? ApplicationSearch.encodeCache(entries)
            : ""
        cacheLoaded = true
        revision += 1
    }

    function reconcile(): void {
        const nextEntries = ApplicationSearch.recordsFromDesktopEntries(
            DesktopEntries.applications.values)
        entries = nextEntries
        rebuildLookup(nextEntries)
        ready = true
        revision += 1

        const payload = ApplicationSearch.encodeCache(nextEntries)
        if (payload !== persistedPayload) {
            pendingPayload = payload
            if (!writeInProgress)
                saveTimer.restart()
        }
    }

    function writePending(): void {
        if (writeInProgress || pendingPayload.length === 0
                || pendingPayload === persistedPayload)
            return

        currentWritePayload = pendingPayload
        pendingPayload = ""
        writeInProgress = true
        cacheFile.setText(currentWritePayload)
    }

    function results(query): var {
        const currentRevision = revision
        return ApplicationSearch.rankRecords(entries, query)
    }

    function recordById(id): var {
        const currentRevision = revision
        return entriesById["id:" + String(id)] ?? null
    }

    function entryById(id): var {
        const record = recordById(id)
        return record?.liveEntry ?? null
    }

    function recordForAppId(appId): var {
        const currentRevision = revision
        return ApplicationSearch.recordForAppId(entries, appId)
    }

    function iconSource(record): string {
        const icon = String(record?.icon || "").trim()
        if (icon.startsWith("/") || icon.startsWith("file:")
                || icon.startsWith("image:") || icon.startsWith("data:"))
            return icon.startsWith("/") ? encodeURI("file://" + icon) : icon

        const candidates = ApplicationSearch.iconNameCandidates(record)
        for (const candidate of candidates) {
            const source = Quickshell.iconPath(candidate, true)
            if (source.length > 0)
                return source
        }
        return Quickshell.iconPath("application-x-executable")
    }

    Component.onCompleted: {
        loadCache()
        if (DesktopEntries.applications.values.length > 0)
            Qt.callLater(reconcile)
        else
            sourceReadyFallback.start()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged(): void {
            root.reconcile()
        }
    }

    Timer {
        id: sourceReadyFallback
        interval: 100
        repeat: false
        onTriggered: {
            if (!root.ready)
                root.reconcile()
        }
    }

    Timer {
        id: saveTimer
        interval: 250
        repeat: false
        onTriggered: root.writePending()
    }

    FileView {
        id: cacheFile
        path: Quickshell.statePath("application-index-v1.json")
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
            root.pendingPayload = ApplicationSearch.encodeCache(root.entries)
            root.warnCache("could not be saved; continuing in memory")
        }
    }
}
