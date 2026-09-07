import QtQuick
import QtTest
import "../../quickdrift-shell/Services/QuickActionsData.js" as QuickActionsData

TestCase {
    name: "QuickActionsData"

    readonly property var firstAction: ({
        id: "first",
        label: "First action",
        icon: "system-run",
        command: "printf 'first'"
    })

    readonly property var secondAction: ({
        id: "second",
        label: "Second action",
        icon: "",
        command: "notify-send Second"
    })

    function test_cacheRoundTripAndMalformedRecovery() {
        const payload = QuickActionsData.encode([
            firstAction,
            secondAction
        ])
        const decoded = QuickActionsData.decode(payload)

        verify(decoded.valid)
        compare(decoded.actions.length, 2)
        compare(decoded.actions[0].id, "first")
        compare(decoded.actions[1].id, "second")
        compare(QuickActionsData.encode(decoded.actions), payload)

        verify(!QuickActionsData.decode("not json").valid)
        verify(!QuickActionsData.decode(JSON.stringify({
            schemaVersion: 99,
            actions: []
        })).valid)
        verify(QuickActionsData.decode("").valid)
    }

    function test_invalidRowsAndDuplicateIdsAreIgnored() {
        const decoded = QuickActionsData.decode(JSON.stringify({
            schemaVersion: 1,
            actions: [
                firstAction,
                {
                    id: "first",
                    label: "Duplicate",
                    command: "true"
                },
                {
                    id: "blank-command",
                    label: "Invalid",
                    command: "  "
                }
            ]
        }))

        verify(decoded.valid)
        compare(decoded.actions.length, 1)
        compare(decoded.actions[0].label, "First action")
    }

    function test_addEditDeleteAndStableOrder() {
        let actions = QuickActionsData.addAction([], firstAction)
        actions = QuickActionsData.addAction(actions, secondAction)
        compare(actions.length, 2)
        compare(actions[0].id, "first")
        compare(actions[1].id, "second")

        actions = QuickActionsData.updateAction(
            actions, "first", "Updated", "folder", "pwd")
        compare(actions[0].label, "Updated")
        compare(actions[0].command, "pwd")
        compare(actions[1].id, "second")

        actions = QuickActionsData.removeAction(actions, "first")
        compare(actions.length, 1)
        compare(actions[0].id, "second")
    }

    function test_reorderingClampsAndPreservesEntries() {
        const thirdAction = {
            id: "third",
            label: "Third action",
            icon: "",
            command: "true"
        }
        let actions = [firstAction, secondAction, thirdAction]

        actions = QuickActionsData.moveAction(actions, "first", 99)
        compare(actions[0].id, "second")
        compare(actions[1].id, "third")
        compare(actions[2].id, "first")

        actions = QuickActionsData.moveAction(actions, "first", -10)
        compare(actions[0].id, "first")
        compare(actions[1].id, "second")
        compare(actions[2].id, "third")
    }

    function test_blankFieldsAreRejected() {
        compare(QuickActionsData.normalizedAction(
            "id", "", "", "true"), null)
        compare(QuickActionsData.normalizedAction(
            "id", "Label", "", "  "), null)
        compare(QuickActionsData.addAction([], {
            id: "id",
            label: "Label",
            command: ""
        }).length, 0)
    }

    function test_uniqueIdAvoidsCollisions() {
        const first = QuickActionsData.uniqueId([], 1000, 1)
        const second = QuickActionsData.uniqueId([{
            id: first,
            label: "Existing",
            icon: "",
            command: "true"
        }], 1000, 1)

        verify(first.length > 0)
        verify(second !== first)
    }

    function test_launchCommandPreservesShellTextAsOneArgument() {
        const command = "printf '%s\\n' \"$HOME\" | head -n 1"
        const launch = QuickActionsData.buildLaunchCommand(command)

        compare(launch.length, 9)
        compare(launch[0], "/usr/bin/systemd-run")
        compare(launch[1], "--user")
        compare(launch[2], "--scope")
        compare(launch[3], "--collect")
        compare(launch[4], "--quiet")
        compare(launch[5], "--")
        compare(launch[6], "/bin/bash")
        compare(launch[7], "-lc")
        compare(launch[8], command)
        compare(QuickActionsData.buildLaunchCommand("  ").length, 0)
    }

    function test_trackedLaunchWrapsDetachedCommandAndStatusPath() {
        const command = "sleep 1; printf done"
        const statusPath = "/tmp/quick-action-result-test"
        const tracked = QuickActionsData.buildTrackedLaunchCommand(
            command, statusPath)

        compare(tracked[0], "/bin/bash")
        compare(tracked[1], "-c")
        compare(tracked[3], "quick-actions-runner")
        compare(tracked[4], statusPath)
        compare(tracked.slice(-9),
            QuickActionsData.buildLaunchCommand(command))
        compare(QuickActionsData.buildTrackedLaunchCommand(
            command, "").length, 0)
    }
}
