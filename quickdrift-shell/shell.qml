//@ pragma UseQApplication

import QtQuick
import QtQml

import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Configs.Settings
import qs.Configs.Themeing
import qs.Modules.Desktop
import qs.Modules.Desktop.Panels
import qs.Modules.Services
import qs.Modules.Driftlets.MinimizeDriftlet
import qs.Modules.Driftlets.ClipboardDriftlet

import qs.Addons


ShellRoot {
    id: root
    
    property bool asciiShown: false
    property bool settingsLoaded: false
    
    signal bootstrap()
    signal bootstrapComplete()

    onSettingsLoadedChanged: { 
        if(settingsLoaded) { 
            console.log("Loading Settings Complete")
            root.bootstrapComplete()
        }
    }

    FileView {
        id: asciiFileView 
        watchChanges: true
        path: Qt.resolvedUrl("./HyprDriftASCII.txt")
        onLoaded:{console.log(text()); root.asciiShown = true}
        onLoadFailed:{console.log("Loaded ascii FAILED")}
    }



    Connections {
        target: root
        function onBootstrap() {
            Settings.activate()
            ThemeSettings.activate()
        }
    }

    Connections {
        target: root
        function onBootstrapComplete() {
            VolumeBroker.activate()
        }
    }

    Component {
        id:isReadyBoolBinding
        Binding{ root.settingsLoaded:Settings.isReady && ThemeSettings.isReady } 
    }

    Loader {
        id: asciiContinueLoader
        active:root.asciiShown
        sourceComponent: isReadyBoolBinding
    }

    Loader {
        id: desktopLoader
        active: root.settingsLoaded
        sourceComponent: Desktop {}
    }

    Loader {
        id: taskbarLoader
        active: root.settingsLoaded
        sourceComponent: Taskbar {}
    }

    Loader {
        id: minimizeWindowLoader
        active: root.settingsLoaded
        sourceComponent: MinimizeWindow {}
    }

    Loader {
        id: globalShortcutsLoader
        active: root.settingsLoaded
        sourceComponent: GlobalShortcuts {}
    }

    // Singletons that need to be instantiated at shell root
    AudioControl { }
    MprisController { }
    ClipboardHistory { }
    MinimizeManager { }
    
}
