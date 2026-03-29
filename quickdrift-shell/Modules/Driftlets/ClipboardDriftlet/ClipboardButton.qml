import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Driftlets.ClipboardDriftlet

RoundButton {
    id: root

    Layout.topMargin: 4
    Layout.bottomMargin: 4
    Layout.fillHeight: true
    Layout.preferredWidth: root.height

    background: Rectangle {
        radius: root.radius
        anchors.fill: parent
        color: root.hovered ? ThemeSettings.clipmanIconBackgroundHover : ThemeSettings.clipmanIconBackground
    }

    Text {
        anchors.horizontalCenter: root.horizontalCenter
        anchors.verticalCenter: root.verticalCenter
        text: "󰅌"
        color: ThemeSettings.fontColor
        font.pixelSize: Settings.taskbar.geometry.height * .66
    }

    ClipboardManager {
        id: clipMenu
        parent: root
    }

    onClicked: {
        clipMenu.swapStates()
    }
}
