//@ pragma UseQApplication

import qs.Internal
import qs.Panels
import qs.Panels.MinimizeManager
import qs.Modules.Interactive
import qs.Modules.Interactive.ClipboardManager
import qs.Modules.Interactive.ApplicationLauncher
import qs.Services
import qs.Services.IconResolver
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

ShellRoot {
    readonly property bool applicationIndexReady: ApplicationIndex.ready
    readonly property bool applicationBarReady: ApplicationBarStore.ready
        && ApplicationWindowModel.ready
    readonly property bool quickActionsReady: QuickActionsStore.ready

    Taskbar {}
    IconResolver {}
    LauncherWindow {}
    MinimizeWindow {}
    GlobalShortcusts {}
    //BtopDisplay {}
    //Logging { }
}
