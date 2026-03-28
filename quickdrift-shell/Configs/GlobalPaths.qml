pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    property string systemSettingsPath: Qt.resolvedUrl("./Settings/SystemSettings.json")
    property string desktopConfigPath: Qt.resolvedUrl("./Settings/DesktopConfig.json")
    property string taskbarConfigPath: Qt.resolvedUrl("./Settings/TaskbarConfig.json")
}