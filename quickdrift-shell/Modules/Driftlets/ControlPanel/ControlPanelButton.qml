import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings

RoundButton {
    id: root

    property point globalPosition: root.mapToGlobal(0,0)
    property int vertPad: 10
    property int horPad: 4
    Layout.topMargin: 4
    Layout.bottomMargin: 4
    Layout.fillHeight: true
    Layout.preferredWidth : root.height
    


    background: Rectangle {
        radius: root.radius
        anchors.fill: parent
        color: root.hovered ? ThemeSettings.base02 : "transparent"
    }

    Text {
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        leftPadding: 1
        text: ""
        color: ThemeSettings.fontColor
    } 

    onClicked: { 
        panel.swapStates()
    }

    ControlPanel {id: panel; parent:root}

    
}