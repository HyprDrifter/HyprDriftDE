pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import QtQml.Models

Singleton {
    id: root

    readonly property int historyLimit: 100
    readonly property int count: entries.data.length

    property JsonAdapter entries: JsonAdapter {
        property var data: []
    }

    property bool loaded: false
    property bool clearing: false
    property int historyGeneration: 0
    property int currentListGeneration: 0

    readonly property string pinPayloadPrefix: Quickshell.statePath("clipboard-pin-")
    readonly property int pinnedCount: Object.keys(pinnedById).length
    readonly property bool pinBusy: pinCaptureProcess.running
        || pinRestoreProcess.running
        || pinCaptureQueue.length > 0
        || pinRestoreQueue.length > 0

    property bool pinStateLoaded: false
    property int pinSerial: 0
    property int pinRevision: 0
    property var pinnedById: ({})
    property var pinPendingById: ({})
    property var pinCaptureQueue: []
    property string currentPinCaptureId: ""
    property string currentPinCapturePath: ""
    property var pinRestoreQueue: []
    property var pinRestoreQueuedById: ({})
    property var pinRestoreFailedById: ({})
    property string currentPinRestoreId: ""
    property string currentPinRestorePath: ""
    property string currentPinRestoreOutput: ""
    property var currentWipePaths: []
    property string currentWipeOutput: ""

    property var fullTextById: ({})
    property var textReadyById: ({})
    property var textErrorById: ({})
    property var textRequestedById: ({})
    property var textQueue: []
    property string currentTextId: ""
    property string currentTextOutput: ""
    property int currentTextGeneration: 0
    property int textRevision: 0

    property var previewReadyById: ({})
    property var previewErrorById: ({})
    property var previewRequestedById: ({})
    property var previewQueue: []
    property string currentPreviewId: ""
    property int currentPreviewGeneration: 0
    property int previewRevision: 0

    property var expandedById: ({})

    function normalizedId(id): string {
        return String(id).trim()
    }

    function validId(id): bool {
        return /^[0-9]+$/.test(normalizedId(id))
    }

    function refresh(): void {
        if (!clearing && !pinRestoreProcess.running && !listProcess.running) {
            currentListGeneration = historyGeneration
            listProcess.running = true
        }
    }

    function loadPinState(): void {
        let contents = ""
        try {
            contents = pinStateFile.text().trim()
        } catch (error) {
            console.warn("Could not read pinned clipboard state:", error)
        }

        const next = ({})
        if (contents.length > 0) {
            try {
                const saved = JSON.parse(contents)
                for (const clipId of Object.keys(saved)) {
                    const path = saved[clipId]
                    if (validId(clipId)
                            && typeof path === "string"
                            && path.indexOf(pinPayloadPrefix) === 0)
                        next[clipId] = path
                }
            } catch (error) {
                console.warn("Ignoring invalid pinned clipboard state:", error)
            }
        }

        pinnedById = next
        pinRevision += 1
        pinStateLoaded = true
        Qt.callLater(refresh)
    }

    function persistPins(): void {
        pinStateFile.setText(JSON.stringify(pinnedById))
    }

    function isPinned(clipId): bool {
        const revision = pinRevision
        return typeof pinnedById[normalizedId(clipId)] === "string"
    }

    function pinPending(clipId): bool {
        const revision = pinRevision
        return pinPendingById[normalizedId(clipId)] === true
    }

    function nextPinPath(clipId): string {
        pinSerial += 1
        return pinPayloadPrefix + Date.now() + "-" + pinSerial + "-" + normalizedId(clipId)
    }

    function togglePinned(clipId): void {
        const id = normalizedId(clipId)
        if (clearing || pinBusy || !validId(id))
            return

        if (isPinned(id)) {
            const path = pinnedById[id]
            const next = Object.assign({}, pinnedById)
            delete next[id]
            pinnedById = next
            pinRevision += 1
            persistPins()
            Quickshell.execDetached(["/usr/bin/rm", "-f", "--", path])
            return
        }

        const pending = Object.assign({}, pinPendingById)
        pending[id] = true
        pinPendingById = pending
        pinRevision += 1
        pinCaptureQueue = pinCaptureQueue.concat([{
            clipId: id,
            path: nextPinPath(id)
        }])
        startNextPinCapture()
    }

    function startNextPinCapture(): void {
        if (clearing || pinCaptureProcess.running || pinCaptureQueue.length === 0)
            return

        const next = pinCaptureQueue[0]
        pinCaptureQueue = pinCaptureQueue.slice(1)
        currentPinCaptureId = next.clipId
        currentPinCapturePath = next.path
        pinCaptureProcess.command = [
            "/usr/bin/bash",
            "-c",
            "set -euo pipefail; /usr/bin/cliphist decode \"$1\" > \"$2\"",
            "clipboard-pin",
            currentPinCaptureId,
            currentPinCapturePath
        ]
        pinCaptureProcess.running = true
    }

    function reconcilePins(nextEntries): void {
        if (!pinStateLoaded || clearing)
            return

        const visible = ({})
        for (const entry of nextEntries)
            visible[entry.clipId] = true

        let queue = pinRestoreQueue
        let queued = Object.assign({}, pinRestoreQueuedById)
        for (const clipId of Object.keys(pinnedById)) {
            if (visible[clipId]
                    || queued[clipId]
                    || pinRestoreFailedById[clipId])
                continue

            queue = queue.concat([{
                clipId: clipId,
                path: pinnedById[clipId]
            }])
            queued[clipId] = true
        }

        pinRestoreQueue = queue
        pinRestoreQueuedById = queued
        startNextPinRestore()
    }

    function startNextPinRestore(): void {
        if (clearing || pinRestoreProcess.running || pinRestoreQueue.length === 0)
            return

        const next = pinRestoreQueue[0]
        pinRestoreQueue = pinRestoreQueue.slice(1)
        currentPinRestoreId = next.clipId
        currentPinRestorePath = next.path
        currentPinRestoreOutput = ""
        pinRestoreProcess.command = [
            "/usr/bin/bash",
            "-c",
            "set -euo pipefail; [ -r \"$1\" ]; /usr/bin/cliphist -max-items 100 store < \"$1\"; /usr/bin/cliphist list | /usr/bin/sed -n '1{s/\\t.*//;p;}'",
            "clipboard-pin-restore",
            currentPinRestorePath
        ]
        pinRestoreProcess.running = true
    }

    function pinnedPathsForClear(): var {
        const paths = []
        const seen = ({})

        for (let index = entries.data.length - 1; index >= 0; --index) {
            const path = pinnedById[entries.data[index].clipId]
            if (typeof path === "string" && !seen[path]) {
                paths.push(path)
                seen[path] = true
            }
        }

        for (const clipId of Object.keys(pinnedById)) {
            const path = pinnedById[clipId]
            if (!seen[path]) {
                paths.push(path)
                seen[path] = true
            }
        }

        return paths
    }

    function rebuiltPinsAfterWipe(output): var {
        if (currentWipePaths.length === 0)
            return ({})

        const contents = output.trim()
        const lines = contents.length === 0 ? [] : contents.split("\n")
        if (lines.length !== currentWipePaths.length)
            return null

        const expected = ({})
        for (const path of currentWipePaths)
            expected[path] = true

        const next = ({})
        for (const line of lines) {
            const separator = line.lastIndexOf("\t")
            if (separator <= 0)
                return null

            const path = line.slice(0, separator)
            const clipId = line.slice(separator + 1).trim()
            if (!expected[path] || !validId(clipId))
                return null
            next[clipId] = path
        }

        if (Object.keys(next).length !== currentWipePaths.length)
            return null
        return next
    }

    function resetDecodedState(): void {
        entries.data = []
        historyGeneration += 1
        fullTextById = ({})
        textReadyById = ({})
        textErrorById = ({})
        textRequestedById = ({})
        textQueue = []
        currentTextId = ""
        currentTextOutput = ""
        previewReadyById = ({})
        previewErrorById = ({})
        previewRequestedById = ({})
        previewQueue = []
        currentPreviewId = ""
        expandedById = ({})
        textRevision += 1
        previewRevision += 1
    }

    function entriesMatch(nextEntries): bool {
        const currentEntries = entries.data
        if (currentEntries.length !== nextEntries.length)
            return false

        for (let index = 0; index < nextEntries.length; ++index) {
            const current = currentEntries[index]
            const next = nextEntries[index]
            if (current.clipId !== next.clipId
                    || current.summary !== next.summary
                    || current.isImage !== next.isImage)
                return false
        }

        return true
    }

    function copy(clipId): void {
        const id = normalizedId(clipId)
        if (!validId(id)) {
            console.warn("Refusing to copy an invalid cliphist id:", id)
            return
        }

        decodeProcess.exec([
            "/usr/bin/bash",
            "-c",
            "set -o pipefail; /usr/bin/cliphist decode \"$1\" | /usr/bin/wl-copy",
            "clipboard-copy",
            id
        ])
    }

    function clearAll(): void {
        if (clearing || pinBusy)
            return

        currentWipePaths = pinnedPathsForClear()
        currentWipeOutput = ""
        clearing = true
        wipeProcess.command = [
            "/usr/bin/bash",
            "-c",
            "set -euo pipefail; for pin_path in \"$@\"; do [ -r \"$pin_path\" ]; done; /usr/bin/cliphist wipe; for pin_path in \"$@\"; do /usr/bin/cliphist -max-items 100 store < \"$pin_path\"; new_id=$(/usr/bin/cliphist list | /usr/bin/sed -n '1{s/\\t.*//;p;}'); [[ \"$new_id\" =~ ^[0-9]+$ ]]; /usr/bin/printf '%s\\t%s\\n' \"$pin_path\" \"$new_id\"; done",
            "clipboard-clear"
        ].concat(currentWipePaths)
        wipeProcess.running = true
    }

    function fullText(clipId): string {
        const revision = textRevision
        const id = normalizedId(clipId)
        return fullTextById[id] || ""
    }

    function fullTextReady(clipId): bool {
        const revision = textRevision
        return textReadyById[normalizedId(clipId)] === true
    }

    function fullTextFailed(clipId): bool {
        const revision = textRevision
        return textErrorById[normalizedId(clipId)] === true
    }

    function requestFullText(clipId): void {
        const id = normalizedId(clipId)
        if (clearing || !validId(id) || textReadyById[id] || textRequestedById[id])
            return

        const requested = Object.assign({}, textRequestedById)
        requested[id] = true
        textRequestedById = requested
        textQueue = textQueue.concat([id])
        startNextTextDecode()
    }

    function startNextTextDecode(): void {
        if (clearing || textDecodeProcess.running || textQueue.length === 0)
            return

        currentTextId = textQueue[0]
        textQueue = textQueue.slice(1)
        currentTextOutput = ""
        currentTextGeneration = historyGeneration
        textDecodeProcess.command = [
            "/usr/bin/cliphist",
            "decode",
            currentTextId
        ]
        textDecodeProcess.running = true
    }

    function setFullText(clipId, value): void {
        const decoded = Object.assign({}, fullTextById)
        decoded[clipId] = value
        fullTextById = decoded

        const ready = Object.assign({}, textReadyById)
        ready[clipId] = true
        textReadyById = ready

        const errors = Object.assign({}, textErrorById)
        delete errors[clipId]
        textErrorById = errors
        textRevision += 1
    }

    function setTextError(clipId): void {
        const errors = Object.assign({}, textErrorById)
        errors[clipId] = true
        textErrorById = errors
        textRevision += 1
    }

    function previewPath(clipId): string {
        return Quickshell.cachePath("clipboard-preview-" + normalizedId(clipId))
    }

    function previewSource(clipId): string {
        const revision = previewRevision
        const id = normalizedId(clipId)
        if (!previewReadyById[id])
            return ""
        return "file://" + previewPath(id) + "?revision=" + revision
    }

    function previewFailed(clipId): bool {
        const revision = previewRevision
        return previewErrorById[normalizedId(clipId)] === true
    }

    function isExpanded(clipId): bool {
        return expandedById[normalizedId(clipId)] === true
    }

    function setExpanded(clipId, expanded): void {
        const id = normalizedId(clipId)
        const next = Object.assign({}, expandedById)
        if (expanded)
            next[id] = true
        else
            delete next[id]
        expandedById = next
    }

    function requestPreview(clipId): void {
        const id = normalizedId(clipId)
        if (clearing || !validId(id) || previewReadyById[id] || previewRequestedById[id])
            return

        const requested = Object.assign({}, previewRequestedById)
        requested[id] = true
        previewRequestedById = requested
        previewQueue = previewQueue.concat([id])
        startNextPreviewDecode()
    }

    function startNextPreviewDecode(): void {
        if (clearing || previewDecodeProcess.running || previewQueue.length === 0)
            return

        currentPreviewId = previewQueue[0]
        previewQueue = previewQueue.slice(1)
        currentPreviewGeneration = historyGeneration
        previewDecodeProcess.command = [
            "/usr/bin/bash",
            "-c",
            "/usr/bin/cliphist decode \"$1\" > \"$2\"",
            "clipboard-preview",
            currentPreviewId,
            previewPath(currentPreviewId)
        ]
        previewDecodeProcess.running = true
    }

    Component.onCompleted: loadPinState()

    FileView {
        id: pinStateFile
        path: Quickshell.statePath("clipboard-pins.json")
        blockLoading: true
        blockWrites: true
        printErrors: false

        onSaveFailed: error => console.warn("Could not save pinned clipboard state:", error)
    }

    Process {
        id: listProcess
        command: [
            "/usr/bin/cliphist",
            "-preview-width", "240",
            "list"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.clearing
                        || root.currentListGeneration !== root.historyGeneration)
                    return

                const contents = text.trim()
                const lines = contents.length === 0
                    ? []
                    : contents.split("\n").slice(0, root.historyLimit)
                const nextEntries = []

                for (const line of lines) {
                    const separator = line.indexOf("\t")
                    if (separator <= 0)
                        continue

                    const clipId = line.slice(0, separator).trim()
                    if (!root.validId(clipId))
                        continue

                    const summary = line.slice(separator + 1).trim()
                    const isImage = /^\[\[ binary data\b/i.test(summary)
                    nextEntries.push({
                        clipId: clipId,
                        summary: summary.length > 0 ? summary : "[[ empty ]]",
                        isImage: isImage
                    })
                }

                if (!root.entriesMatch(nextEntries))
                    entries.data = nextEntries
                root.loaded = true
                root.reconcilePins(nextEntries)
            }
        }

        stderr: SplitParser {
            onRead: data => console.warn("cliphist list failed:", data)
        }
    }

    Process {
        id: decodeProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Failed to copy clipboard entry:", exitCode, exitStatus)
        }
    }

    Process {
        id: pinCaptureProcess

        onExited: (exitCode, exitStatus) => {
            const completedId = root.currentPinCaptureId
            const completedPath = root.currentPinCapturePath
            root.currentPinCaptureId = ""
            root.currentPinCapturePath = ""

            const pending = Object.assign({}, root.pinPendingById)
            delete pending[completedId]
            root.pinPendingById = pending

            if (exitCode === 0 && root.validId(completedId)) {
                const next = Object.assign({}, root.pinnedById)
                next[completedId] = completedPath
                root.pinnedById = next
                root.persistPins()
            } else {
                console.warn("Could not pin clipboard entry:", exitCode, exitStatus)
                Quickshell.execDetached(["/usr/bin/rm", "-f", "--", completedPath])
            }

            root.pinRevision += 1
            Qt.callLater(root.startNextPinCapture)
        }

        stderr: SplitParser {
            onRead: data => console.warn("Could not pin clipboard entry:", data)
        }
    }

    Process {
        id: pinRestoreProcess

        stdout: StdioCollector {
            onStreamFinished: root.currentPinRestoreOutput = text
        }

        onExited: (exitCode, exitStatus) => {
            const oldId = root.currentPinRestoreId
            const path = root.currentPinRestorePath
            const newId = root.currentPinRestoreOutput.trim()
            root.currentPinRestoreId = ""
            root.currentPinRestorePath = ""
            root.currentPinRestoreOutput = ""

            const queued = Object.assign({}, root.pinRestoreQueuedById)
            delete queued[oldId]
            root.pinRestoreQueuedById = queued

            if (exitCode === 0 && root.validId(newId)) {
                const next = Object.assign({}, root.pinnedById)
                if (next[oldId] === path)
                    delete next[oldId]
                next[newId] = path
                root.pinnedById = next

                const failures = Object.assign({}, root.pinRestoreFailedById)
                delete failures[oldId]
                root.pinRestoreFailedById = failures
                root.persistPins()
                root.pinRevision += 1
                Qt.callLater(root.refresh)
            } else {
                const failures = Object.assign({}, root.pinRestoreFailedById)
                failures[oldId] = true
                root.pinRestoreFailedById = failures
                root.pinRevision += 1
                console.warn("Could not restore pinned clipboard entry:", exitCode, exitStatus)
            }

            Qt.callLater(root.startNextPinRestore)
        }

        stderr: SplitParser {
            onRead: data => console.warn("Could not restore pinned clipboard entry:", data)
        }
    }

    Process {
        id: wipeProcess

        stdout: StdioCollector {
            onStreamFinished: root.currentWipeOutput = text
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.clearing = false
                console.warn("Failed to clear clipboard history:", exitCode, exitStatus)
                Qt.callLater(root.startNextTextDecode)
                Qt.callLater(root.startNextPreviewDecode)
                Qt.callLater(root.refresh)
                return
            }

            const rebuiltPins = root.rebuiltPinsAfterWipe(root.currentWipeOutput)
            if (rebuiltPins === null) {
                console.warn("Pinned clipboard entries were restored, but their new ids could not be read; retrying reconciliation")
            } else {
                root.pinnedById = rebuiltPins
                root.persistPins()
                root.pinRevision += 1
            }

            root.currentWipePaths = []
            root.currentWipeOutput = ""
            root.pinRestoreQueue = []
            root.pinRestoreQueuedById = ({})
            root.pinRestoreFailedById = ({})
            root.resetDecodedState()
            root.clearing = false
            Qt.callLater(root.refresh)
        }
    }

    Process {
        id: textDecodeProcess

        stdout: StdioCollector {
            onStreamFinished: root.currentTextOutput = text
        }

        onExited: (exitCode, exitStatus) => {
            const completedId = root.currentTextId
            const completedText = root.currentTextOutput
            const completedGeneration = root.currentTextGeneration
            root.currentTextId = ""
            root.currentTextOutput = ""

            if (root.clearing
                    && completedGeneration === root.historyGeneration
                    && completedId.length > 0) {
                root.textQueue = [completedId].concat(root.textQueue)
            } else if (!root.clearing
                    && completedGeneration === root.historyGeneration
                    && completedId.length > 0) {
                if (exitCode === 0)
                    root.setFullText(completedId, completedText)
                else {
                    root.setTextError(completedId)
                    console.warn("Could not decode clipboard text:", exitCode, exitStatus)
                }
            }

            Qt.callLater(root.startNextTextDecode)
        }

        stderr: SplitParser {
            onRead: data => {
                if (!root.clearing)
                    console.warn("Could not decode clipboard text:", data)
            }
        }
    }

    Process {
        id: previewDecodeProcess

        onExited: (exitCode, exitStatus) => {
            const completedId = root.currentPreviewId
            const completedGeneration = root.currentPreviewGeneration
            root.currentPreviewId = ""

            if (root.clearing
                    && completedGeneration === root.historyGeneration
                    && completedId.length > 0) {
                root.previewQueue = [completedId].concat(root.previewQueue)
            } else if (!root.clearing
                    && completedGeneration === root.historyGeneration
                    && exitCode === 0
                    && completedId.length > 0) {
                const ready = Object.assign({}, root.previewReadyById)
                ready[completedId] = true
                root.previewReadyById = ready

                const errors = Object.assign({}, root.previewErrorById)
                delete errors[completedId]
                root.previewErrorById = errors
                root.previewRevision += 1
            } else if (!root.clearing
                    && completedGeneration === root.historyGeneration
                    && completedId.length > 0) {
                const errors = Object.assign({}, root.previewErrorById)
                errors[completedId] = true
                root.previewErrorById = errors
                root.previewRevision += 1
                console.warn("Could not decode clipboard image preview:", exitCode, exitStatus)
            }

            Qt.callLater(root.startNextPreviewDecode)
        }

        stderr: SplitParser {
            onRead: data => {
                if (!root.clearing)
                    console.warn("Clipboard image preview failed:", data)
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
