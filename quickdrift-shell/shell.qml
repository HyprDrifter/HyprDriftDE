//@ pragma UseQApplication

import "./Internal/"
import "./Panels/"
import "./Panels/MinimizeManager"
import "./Scripts/"
import "./Modules/"
import "./Modules/Interactive/"
import "./Modules/Interactive/ClipboardManager"
import "./Modules/Interactive/ApplicationLauncher"
import "./Services/"
import "./Services/IconResolver"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

ShellRoot {
    Taskbar {}
    IconResolver {}
    LauncherWindow {}
    MinimizeWindow {}
    GlobalShortcusts {}
    //BtopDisplay {}
    //Logging { }
}
