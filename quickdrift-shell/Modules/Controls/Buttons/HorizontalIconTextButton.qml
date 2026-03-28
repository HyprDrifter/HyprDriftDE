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

    property QtObject entry
    property string imageContentPath
    property bool selected
    property color backgroundColor: (root.hovered || selected) && enabled ? ThemeSettings.buttons.backgroundColorHovered : "Transparent"
    property var executeAction
    property int btnWidth: btnIcon.width + btnText.width
    property real borderWidth : 1
    property int radius : 0
    enabled : true

    implicitHeight: 40
    implicitWidth: parent?.width ?? 0
    
    background: Rectangle{
        id:btnBackRect
        color: root.backgroundColor
        anchors.fill: parent
        radius: root.radius
        
        border {
            width: root.hovered ? root.borderWidth + 1 :root.borderWidth 
            color: ThemeSettings.taskbarTrayBorderColor
        }
        RowLayout {
            parent: btnBackRect
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Image {
                id: btnIcon
                Layout.leftMargin: 10
                Layout.preferredHeight: parent.height 
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: height
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                source: Qt.resolvedUrl(root?.imageContentPath) ?? null
            }
            Text {
                id: btnText
                Layout.alignment: Qt.AlignLeft
                color: root.enabled ? ThemeSettings.fontColor : ThemeSettings.fontColorInactive
                text: root.textContent
            }
        }
    }
}