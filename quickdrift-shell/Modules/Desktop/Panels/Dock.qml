import QtQuick
import QtQuick.Layouts
import QtQml

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Services

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockPanel

            required property var modelData
            screen: modelData
            color: "transparent"

            anchors {
                bottom: true
                left: true
                right: true
            }

            implicitHeight: 60

            Rectangle {
                anchors.fill: parent
                color: ThemeSettings.background
                radius: Settings.taskbar.geometry.radius

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                }
            }
        }
    }
}
