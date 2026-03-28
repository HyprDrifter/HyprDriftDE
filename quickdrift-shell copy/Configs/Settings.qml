pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Configs.Settings
import qs.Configs.Themeing

Singleton {
    id: root

    property JsonObject system: systemsettings.settings 
    property JsonObject desktop: desktopConfig.settings
    property JsonObject taskbar: taskbarConfig.settings 

    signal activated()
    signal ready()
    property bool isActive: false
    property bool isReady: false

    property int _pendingLoads: 3

    function _markLoaded() {
        if (isReady) return
        _pendingLoads--
        if (_pendingLoads <= 0) { isReady = true; ready(); console.log("---------------------------------") }
    }

    function activate() {
        if (isActive) return
        isActive = true
        activated()
    }

    SettingsLoader {
        id: systemsettings
        relativePath: GlobalPaths.systemSettingsPath
        configObject: SystemSettings { }
        onLoaded: root._markLoaded()
        onUpdated: {root.system = settings}
    }
    SettingsLoader {
        id: desktopConfig
        relativePath: GlobalPaths.desktopConfigPath
        configObject: DesktopConfig { }
        onLoaded: root._markLoaded()
        onUpdated: {root.desktop = settings}
    }
    SettingsLoader {
        id: taskbarConfig
        relativePath: GlobalPaths.taskbarConfigPath
        configObject: TaskbarConfig { }
        onLoaded: root._markLoaded()
    }
}