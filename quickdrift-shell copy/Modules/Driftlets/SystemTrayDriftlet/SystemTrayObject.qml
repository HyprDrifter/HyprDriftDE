pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Driftlets.SystemTrayDriftlet

Rectangle {
    id: root

    implicitHeight: parent.height * .75
    implicitWidth: systemTrayLayout.width * 1.1
    Layout.minimumWidth: 3
    Layout.minimumHeight: 1
    radius: Settings.taskbar.geometry.radius
    color: '#38000000'

    border {
        color: ThemeSettings.taskbarTrayBorderColor
        width: 1
    }

    RowLayout {
        id: systemTrayLayout

        anchors.centerIn: parent
        Layout.fillHeight: true
        Layout.fillWidth: true

        Layout.alignment: Qt.AlignCenter
        spacing: 0

        Instantiator {
            id: trayItemInstantiator
            model: SystemTray.items

            delegate: TrayItem {
                id: tItem

                required property var model
                required property SystemTrayItem modelData

                iconSize: root.height
                trayItem: modelData

                parent: systemTrayLayout
                parentContainer: root
            }
        }
    }
}
