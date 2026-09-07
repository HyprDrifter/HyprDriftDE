pragma Singleton

import Quickshell
import QtQuick
import "ApplicationLaunch.js" as ApplicationLaunch

Singleton {
    id: root

    function launch(command, workingDirectory): bool {
        const scopedCommand = ApplicationLaunch.scopedCommand(command)
        if (scopedCommand.length === 0)
            return false

        const context = { command: scopedCommand }
        const directory = String(workingDirectory || "").trim()
        if (directory.length > 0)
            context.workingDirectory = directory

        Quickshell.execDetached(context)
        return true
    }

    function launchDesktopId(desktopId): bool {
        const entry = ApplicationIndex.entryById(desktopId)
        if (!entry)
            return false
        return launch(entry.command, entry.workingDirectory)
    }

    function launchShellCommand(command): bool {
        const text = String(command || "").trim()
        if (text.length === 0)
            return false
        return launch(["/bin/bash", "-lc", text], "")
    }
}
