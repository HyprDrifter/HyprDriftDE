//@ pragma UseQApplication

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

import qs.Internal
import qs.Modules.Panels
import qs.Modules.Panels.MinimizeManager
import qs.Modules.Interactive
import qs.Modules.Interactive.ClipboardManager
import qs.Modules.Interactive.ApplicationLauncher
import qs.Services
import qs.Services.IconResolver

ShellRoot {
    Taskbar {}
    IconResolver {}
    LauncherWindow {}
    MinimizeWindow {}
    GlobalShortcusts {}
    //BtopDisplay {}
    //Logging { }
}
