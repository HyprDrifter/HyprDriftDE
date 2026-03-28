import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Desktop
import qs.Modules.Desktop.Panels


Scope {
    Variants{
        model: Quickshell.screens

        PanelWindow {
            id: taskbarRoot

            required property var modelData

            screen: modelData
            color: '#000000'
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: false
            focusable: true

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Background { }
            MouseArea {
                id: desktopMouseArea

                hoverEnabled: true
                anchors.fill: parent

            }
        }
    }
}