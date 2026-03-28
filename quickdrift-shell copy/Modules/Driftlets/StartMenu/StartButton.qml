import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Driftlets.ControlPanel
import qs.Modules.Driftlets.StartMenu

Button {
    id: root

    property int vertPad: 5
    implicitWidth: startText.width
    Layout.fillHeight: true
    Layout.topMargin: vertPad
    Layout.bottomMargin: vertPad
    Layout.preferredWidth: startText.width * 5

    background: Rectangle {
        id: btnRect

        anchors.fill: parent
        radius:Settings.taskbar.geometry.radius
        color: !root.hovered ? "transparent" : ThemeSettings.mantle
    }

    Text {
        id: startText
        text: "\udb82\udcc7"
        color: ThemeSettings.fontColor
        anchors{
            centerIn: parent
        }
    }

    onClicked: { menu.toggle();}

    StartMenu {id: menu; parent: root}
}