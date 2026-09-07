import QtQuick
import QtTest
import "../../quickdrift-shell/Services/ApplicationBarData.js" as ApplicationBarData
import "../../quickdrift-shell/Services/ApplicationLaunch.js" as ApplicationLaunch

TestCase {
    name: "ApplicationBarData"

    function record(id, name) {
        return {
            id: id,
            name: name,
            available: true
        }
    }

    function windowRow(groupId, desktopId, name, firstSeen, mru, active) {
        return {
            groupId: groupId,
            desktopId: desktopId,
            appId: desktopId,
            name: name,
            record: desktopId.length > 0
                ? record(desktopId, name)
                : null,
            toplevel: { title: name + " window " + firstSeen },
            title: name + " window " + firstSeen,
            firstSeen: firstSeen,
            mru: mru,
            activated: active === true
        }
    }

    function test_stateRoundTripAndMalformedRecovery() {
        const payload = ApplicationBarData.encode([
            "firefox.desktop",
            "spotify.desktop",
            "firefox.desktop",
            ""
        ])
        const decoded = ApplicationBarData.decode(payload)

        verify(decoded.valid)
        compare(decoded.pinnedIds.length, 2)
        compare(decoded.pinnedIds[0], "firefox.desktop")
        compare(decoded.pinnedIds[1], "spotify.desktop")
        compare(ApplicationBarData.encode(decoded.pinnedIds), payload)
        verify(!ApplicationBarData.decode("not json").valid)
        verify(!ApplicationBarData.decode(JSON.stringify({
            schemaVersion: 9,
            pinnedDesktopIds: []
        })).valid)
        verify(ApplicationBarData.decode("").valid)
    }

    function test_pinUnpinMoveAndPrune() {
        let pins = ApplicationBarData.pin([], "firefox.desktop")
        pins = ApplicationBarData.pin(pins, "spotify.desktop")
        pins = ApplicationBarData.pin(pins, "code.desktop")
        pins = ApplicationBarData.pin(pins, "firefox.desktop")
        compare(pins.length, 3)

        pins = ApplicationBarData.movePin(pins, "code.desktop", 0)
        compare(pins[0], "code.desktop")
        compare(pins[1], "firefox.desktop")
        compare(pins[2], "spotify.desktop")

        pins = ApplicationBarData.unpin(pins, "firefox.desktop")
        compare(pins.length, 2)
        verify(!ApplicationBarData.isPinned(pins, "firefox.desktop"))

        pins = ApplicationBarData.prunePins(pins, ["spotify.desktop"])
        compare(pins.length, 1)
        compare(pins[0], "spotify.desktop")
    }

    function test_groupedWindowsAndMostRecentOrdering() {
        const firefox = record("firefox.desktop", "Firefox")
        const groups = ApplicationBarData.buildGroups([
            {
                groupId: "desktop:spotify.desktop",
                desktopId: "spotify.desktop",
                record: record("spotify.desktop", "Spotify")
            },
            {
                groupId: "desktop:firefox.desktop",
                desktopId: "firefox.desktop",
                record: firefox
            }
        ], [
            windowRow("desktop:firefox.desktop", "firefox.desktop",
                "Firefox", 1, 3, false),
            windowRow("desktop:firefox.desktop", "firefox.desktop",
                "Firefox", 2, 8, true),
            windowRow("desktop:terminal.desktop", "terminal.desktop",
                "Terminal", 3, 4, false)
        ])

        compare(groups.length, 3)
        compare(groups[0].desktopId, "spotify.desktop")
        verify(groups[0].pinned)
        verify(!groups[0].running)
        compare(groups[1].desktopId, "firefox.desktop")
        compare(groups[1].windowCount, 2)
        verify(groups[1].active)
        compare(groups[1].windows[0].firstSeen, 2)
        compare(groups[2].desktopId, "terminal.desktop")
        verify(!groups[2].pinned)
    }

    function test_groupIdentitySurvivesClosingOneOfSeveralWindows() {
        const first = windowRow("desktop:firefox.desktop",
            "firefox.desktop", "Firefox", 1, 2, false)
        const second = windowRow("desktop:firefox.desktop",
            "firefox.desktop", "Firefox", 2, 1, false)
        const beforeClose = ApplicationBarData.buildGroups([], [
            first,
            second
        ])
        const afterClose = ApplicationBarData.buildGroups([], [second])

        compare(beforeClose[0].modelKey, "desktop:firefox.desktop")
        compare(beforeClose[0].windowCount, 2)
        compare(afterClose[0].modelKey, beforeClose[0].modelKey)
        compare(afterClose[0].windowCount, 1)
        compare(afterClose[0].windows[0].toplevel, second.toplevel)
    }

    function test_unresolvedApplicationStillProducesAGroup() {
        const groups = ApplicationBarData.buildGroups([], [
            windowRow("app:unknown", "", "Unknown App", 1, 0, false)
        ])

        compare(groups.length, 1)
        compare(groups[0].groupId, "app:unknown")
        compare(groups[0].desktopId, "")
        verify(groups[0].running)
        verify(!groups[0].available)
    }

    function test_modalWindowsResolveToTheirApplicationRoot() {
        const application = { appId: "firefox", parent: null }
        const dialog = { appId: "firefox-dialog", parent: application }
        const nestedDialog = { appId: "portal", parent: dialog }

        compare(ApplicationBarData.applicationRoot(dialog), application)
        compare(ApplicationBarData.applicationRoot(nestedDialog), application)
        compare(ApplicationBarData.applicationRoot(application), application)
    }

    function test_scopedLaunchArguments() {
        const command = ApplicationLaunch.scopedCommand([
            "/usr/bin/firefox",
            "--new-window"
        ])
        compare(command, [
            "/usr/bin/systemd-run",
            "--user",
            "--scope",
            "--collect",
            "--quiet",
            "--",
            "/usr/bin/firefox",
            "--new-window"
        ])
        compare(ApplicationLaunch.scopedCommand([]), [])
    }
}
