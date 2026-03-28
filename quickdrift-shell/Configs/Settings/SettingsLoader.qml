pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Desktop
import qs.Modules.Desktop.Panels
import qs.Modules.Services

Scope {
    id: root

    signal loaded()
    signal updated()

    required property string relativePath
    required property JsonObject configObject

    readonly property string fileName: relativePath.split('/').find(p => p.includes(".json"))
    readonly property string fileNameNoExtention: fileName.split('.')[0].trim()
    readonly property alias settings: root.configObject

    FileView {
        id: fileView
        watchChanges: true
        path: Qt.resolvedUrl(root.relativePath)

        onLoaded: { 
            Logger.logWithHeader([
                root.fileNameNoExtention,
                `Loading`
            ])
            if(text() == "")
            {
                Logger.log("- Writing initial Configs")
                fileView.writeAdapter()
            }
            Logger.log("- Loading Complete")
            root.loaded()
        }
        onLoadFailed: { console.log("!!!! FAILED TO LOAD :",root.fileNameNoExtention) }
        onFileChanged: { console.log("reloading :",root.fileNameNoExtention); root.updated(); reload()}
        //atomicWrites: true
        onAdapterUpdated: writeAdapter()
        onAdapterChanged: writeAdapter()

        JsonAdapter {
            id: jAdapter
            property JsonObject settings: root.configObject
        }
    }
}