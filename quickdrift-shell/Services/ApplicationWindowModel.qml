pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQml.Models
import qs.Panels.MinimizeManager
import "ApplicationBarData.js" as ApplicationBarData
import "ApplicationSearch.js" as ApplicationSearch

Singleton {
    id: root

    property var groups: []
    property var trackedWindows: []
    property int revision: 0
    property int orderingSerial: 0
    property int mruSerial: 0
    property var pendingMinimizeToplevel: null
    property int pendingMinimizeAttempts: 0
    property var pendingMaximizeToplevel: null
    property bool pendingMaximizeState: false
    property int pendingMaximizeAttempts: 0
    readonly property bool ready: ApplicationIndex.ready

    function stateFor(toplevel): var {
        for (const state of trackedWindows) {
            if (state.toplevel === toplevel)
                return state
        }
        return null
    }

    function trackWindow(toplevel): void {
        if (!toplevel || stateFor(toplevel))
            return

        orderingSerial += 1
        const activeOrder = toplevel.activated ? ++mruSerial : 0
        trackedWindows = trackedWindows.concat([{
            toplevel: toplevel,
            firstSeen: orderingSerial,
            mru: activeOrder
        }])
        scheduleRebuild()
    }

    function untrackWindow(toplevel): void {
        if (pendingMinimizeToplevel === toplevel)
            pendingMinimizeToplevel = null
        if (pendingMaximizeToplevel === toplevel)
            pendingMaximizeToplevel = null

        const next = trackedWindows.filter(state => state.toplevel !== toplevel)
        if (next.length === trackedWindows.length)
            return
        trackedWindows = next
        scheduleRebuild()
    }

    function handleWindowChanged(toplevel, activationChanged): void {
        const state = stateFor(toplevel)
        if (state && activationChanged && toplevel?.activated)
            state.mru = ++mruSerial
        scheduleRebuild()
    }

    function scheduleRebuild(): void {
        rebuildTimer.restart()
    }

    function windowRow(state): var {
        const toplevel = state?.toplevel
        if (!toplevel)
            return null

        const applicationToplevel = ApplicationBarData.applicationRoot(
            toplevel)
        const reportedAppId = String(applicationToplevel?.appId
            || toplevel.appId || "").trim()
        const record = ApplicationIndex.recordForAppId(reportedAppId)
        const desktopId = String(record?.id || "")
        let groupId = desktopId.length > 0
            ? "desktop:" + desktopId
            : ""
        if (groupId.length === 0) {
            const appKey = ApplicationSearch.normalizeAppIdentifier(
                reportedAppId)
            groupId = appKey.length > 0
                ? "app:" + appKey
                : "window:" + state.firstSeen
        }

        const fallbackName = reportedAppId.length > 0
            ? reportedAppId
            : String(applicationToplevel?.title
                || toplevel.title || "Application")
        return {
            groupId: groupId,
            desktopId: desktopId,
            appId: reportedAppId,
            name: record?.name || fallbackName,
            record: record,
            toplevel: toplevel,
            title: String(toplevel.title || fallbackName),
            firstSeen: state.firstSeen,
            mru: state.mru,
            activated: toplevel.activated === true
        }
    }

    function rebuild(): void {
        const pinnedRows = []
        for (const desktopId of ApplicationBarStore.pinnedIds) {
            pinnedRows.push({
                groupId: "desktop:" + desktopId,
                desktopId: desktopId,
                record: ApplicationIndex.recordById(desktopId)
            })
        }

        const windowRows = []
        for (const state of trackedWindows) {
            const row = windowRow(state)
            if (row)
                windowRows.push(row)
        }

        groups = ApplicationBarData.buildGroups(pinnedRows, windowRows)
        revision += 1
    }

    function hyprlandToplevelFor(toplevel): var {
        for (const candidate of Hyprland.toplevels.values) {
            if (candidate.wayland === toplevel)
                return candidate
        }
        return null
    }

    function minimizedAddressFor(toplevel): string {
        const minimizedAddress = customMinimizedAddressFor(toplevel)
        if (minimizedAddress.length > 0)
            return minimizedAddress

        const hyprlandToplevel = hyprlandToplevelFor(toplevel)
        return String(hyprlandToplevel?.address || "")
    }

    function customMinimizedAddressFor(toplevel): string {
        for (let index = 0;
                index < MinimizeManager.minimizedWindows.count; index++) {
            const minimized = MinimizeManager.minimizedWindows.get(index)
            if (minimized?.topLevel === toplevel)
                return String(minimized.address || "")
        }
        return ""
    }

    function isWindowMinimized(toplevel): bool {
        return Boolean(toplevel && (toplevel.minimized
            || customMinimizedAddressFor(toplevel).length > 0))
    }

    function isWindowMaximized(toplevel): bool {
        return Boolean(toplevel?.maximized)
    }

    function activateWindow(toplevel): bool {
        if (!toplevel)
            return false

        const address = minimizedAddressFor(toplevel)
        if (address.length > 0
                && MinimizeManager.minimizedWindowIndex(address) >= 0) {
            if (MinimizeManager.operationInProgress)
                return false
            MinimizeManager.restoreWindow(address)
            return true
        }

        if (toplevel.minimized)
            toplevel.minimized = false
        toplevel.activate()
        return true
    }

    function toggleWindowMinimized(toplevel): bool {
        if (!toplevel)
            return false

        const minimizedAddress = customMinimizedAddressFor(toplevel)
        if (minimizedAddress.length > 0) {
            if (MinimizeManager.operationInProgress)
                return false
            MinimizeManager.restoreWindow(minimizedAddress)
            return true
        }

        if (toplevel.minimized) {
            toplevel.minimized = false
            toplevel.activate()
            return true
        }

        if (MinimizeManager.operationInProgress
                || pendingMinimizeToplevel !== null)
            return false

        if (ToplevelManager.activeToplevel === toplevel
                || toplevel.activated) {
            MinimizeManager.minimizeFocusedWindow()
            return true
        }

        pendingMinimizeToplevel = toplevel
        pendingMinimizeAttempts = 0
        toplevel.activate()
        pendingMinimizeTimer.restart()
        return true
    }

    function continuePendingMinimize(): void {
        const toplevel = pendingMinimizeToplevel
        if (!toplevel)
            return

        pendingMinimizeAttempts += 1
        if (!MinimizeManager.operationInProgress
                && (ToplevelManager.activeToplevel === toplevel
                    || toplevel.activated)) {
            pendingMinimizeToplevel = null
            MinimizeManager.minimizeFocusedWindow()
            return
        }

        if (pendingMinimizeAttempts >= 20) {
            console.warn("Application bar could not focus the requested window before minimizing it")
            pendingMinimizeToplevel = null
            return
        }

        if (!MinimizeManager.operationInProgress)
            toplevel.activate()
        pendingMinimizeTimer.restart()
    }

    function toggleWindowMaximized(toplevel): bool {
        if (!toplevel || pendingMaximizeToplevel !== null)
            return false

        const targetState = !toplevel.maximized
        const minimizedAddress = customMinimizedAddressFor(toplevel)
        if (minimizedAddress.length > 0) {
            if (MinimizeManager.operationInProgress)
                return false
            pendingMaximizeToplevel = toplevel
            pendingMaximizeState = targetState
            pendingMaximizeAttempts = 0
            MinimizeManager.restoreWindow(minimizedAddress)
            pendingMaximizeTimer.restart()
            return true
        }

        if (toplevel.minimized)
            toplevel.minimized = false
        toplevel.maximized = targetState
        toplevel.activate()
        return true
    }

    function continuePendingMaximize(): void {
        const toplevel = pendingMaximizeToplevel
        if (!toplevel)
            return

        pendingMaximizeAttempts += 1
        const stillMinimized = customMinimizedAddressFor(toplevel).length > 0
        if (!MinimizeManager.operationInProgress && !stillMinimized) {
            if (toplevel.minimized)
                toplevel.minimized = false
            toplevel.maximized = pendingMaximizeState
            toplevel.activate()
            pendingMaximizeToplevel = null
            return
        }

        if (pendingMaximizeAttempts >= 40) {
            console.warn("Application bar timed out while restoring a window for maximize")
            pendingMaximizeToplevel = null
            return
        }
        pendingMaximizeTimer.restart()
    }

    function activateMostRecent(group): bool {
        if (!group || !group.windows || group.windows.length === 0)
            return false
        return activateWindow(group.windows[0].toplevel)
    }

    function launchGroup(group): bool {
        const desktopId = String(group?.desktopId || "")
        return desktopId.length > 0
            && ApplicationLaunchService.launchDesktopId(desktopId)
    }

    function closeWindow(toplevel): bool {
        if (!toplevel)
            return false
        toplevel.close()
        return true
    }

    function closeMostRecent(group): bool {
        if (!group || !group.windows || group.windows.length === 0)
            return false
        return closeWindow(group.windows[0].toplevel)
    }

    function closeGroup(group): bool {
        if (!group || !group.windows || group.windows.length === 0)
            return false
        const windows = group.windows.slice()
        for (const windowRow of windows)
            closeWindow(windowRow.toplevel)
        return true
    }

    Component.onCompleted: scheduleRebuild()

    Timer {
        id: rebuildTimer
        interval: 0
        repeat: false
        onTriggered: root.rebuild()
    }

    Timer {
        id: pendingMinimizeTimer
        interval: 50
        repeat: false
        onTriggered: root.continuePendingMinimize()
    }

    Timer {
        id: pendingMaximizeTimer
        interval: 50
        repeat: false
        onTriggered: root.continuePendingMaximize()
    }

    Instantiator {
        model: ToplevelManager.toplevels

        Connections {
            required property Toplevel modelData
            property var trackedWindow: modelData
            target: modelData

            Component.onCompleted: root.trackWindow(trackedWindow)
            Component.onDestruction: root.untrackWindow(trackedWindow)

            function onAppIdChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onTitleChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onActivatedChanged(): void {
                root.handleWindowChanged(trackedWindow, true)
            }
            function onScreensChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onParentChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onMinimizedChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onMaximizedChanged(): void {
                root.handleWindowChanged(trackedWindow, false)
            }
            function onClosed(): void {
                root.scheduleRebuild()
            }
        }
    }

    Connections {
        target: ApplicationIndex
        function onRevisionChanged(): void {
            root.scheduleRebuild()
        }
    }

    Connections {
        target: ApplicationBarStore
        function onRevisionChanged(): void {
            root.scheduleRebuild()
        }
    }

    Connections {
        target: MinimizeManager.minimizedWindows
        function onCountChanged(): void {
            root.scheduleRebuild()
        }
    }
}
