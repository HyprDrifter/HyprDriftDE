pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import Quickshell
import Quickshell.Io

import qs.Configs.Settings

Singleton {
    id: root

    property string iconDirectory: ThemeSettings.iconDirectory
    property list<QtObject> iconList: []
    
    property FolderListModel listModel : FolderListModel {
        folder: Qt.resolvedUrl(root.iconDirectory)
        nameFilters: ["*.svg", "*.png", "*.jpg", "*.jpeg", "*.ico"]
    }
    
    Instantiator {
        id: folderInstantiator

        model: root.listModel
        delegate: QtObject {
            id: del
            required property QtObject model
            required property string fileName
            property string name: model.fileName
            property string filePath: model.filePath
            property string fileUrl: model.fileUrl
            property bool fileIsDir: model.fileIsDir
        }
        onObjectAdded: (index, object) => addToIconList(index,object)
        onObjectRemoved: (index, object) => removeFromIconList(index,object)

        function addToIconList(index,object) {
            //console.log(object.filePath)
            root.iconList.push(object)
        }

        function removeFromIconList(index, object) {
            root.iconList.splice(index)
        }
    } 

    function findIcon(entry) {

        if(entry)
        {
            var splitPath = entry.icon.split("/") ?? null

            if(splitPath.length > 1) 
            {
                return entry.icon
            } 
            else if (entry && entry.name) 
            {
                var appname = entry.name.toLowerCase()
                var icon = entry.icon ?? ""
                if(icon.includes("steam_icon"))
                {
                    //console.log("Steam Game")
                }
                else if (appname)
                {
                    var ic = root.iconList.find(i => i.fileName.toLowerCase().includes(appname))
                    return ic ? ic.filePath : ""
                }
                else 
                {
                    return "/usr/share/applications/" + entry.name
                }
            }
        }
        return ""
    }
}