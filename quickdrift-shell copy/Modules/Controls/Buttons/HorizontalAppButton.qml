import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Modules.Controls.Buttons
import qs.Modules.Services
import qs.Configs.Settings

ButtonDefault {
    id: root

    signal executed()

    property DesktopEntry entry
    property string imageContentPath
    property bool selected
    property color backgroundColor: root.hovered || selected ? ThemeSettings.buttons.backgroundColorHovered : "Transparent"

    textContent: entry.name ?? ""
    imageContentPath : entry.imagePath
    implicitHeight: 40
    implicitWidth: parent?.width ?? 0
    
    background: Rectangle{
        color: root.backgroundColor
        anchors.fill: parent
        border {
            width: 1
            color: ThemeSettings.taskbarTrayBorderColor
        }
        RowLayout {
            anchors.fill: parent

            Image {
                Layout.preferredHeight: parent.height * .8
                Layout.fillWidth: true
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 1
                source: Qt.resolvedUrl(root?.imageContentPath) ?? null
            }
            Text {
                color: ThemeSettings.fontColor
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 4
                text: root.textContent
            }
        }
    }

    onTextContentChanged: {
        if(root.entry)
        {
            entry.imagePath = IconResolver.findIcon(entry)
        }
        
    }

    onClicked: {
        execute()
    }

    function execute () {
        console.log(entry.execString)
        entry.execute()
        root.executed()
    }
}