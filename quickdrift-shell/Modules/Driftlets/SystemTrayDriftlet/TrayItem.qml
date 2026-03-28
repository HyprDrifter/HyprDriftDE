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
    
    required property QtObject trayItem
    required property var parentContainer
    required property int iconSize
    property real iconScale: .60
    property real adjustedSize: iconSize * iconScale
    property int itemPadding: 2
    Layout.leftMargin: 2
    Layout.rightMargin : 2
    radius: 360
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: adjustedSize + itemPadding
    Layout.preferredWidth: adjustedSize + itemPadding
    color: iconMouseArea.containsMouse ? ThemeSettings.buttons.backgroundColorHovered : "transparent"

    MouseArea {
        id: iconMouseArea

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        anchors {
            centerIn: parent
            fill: parent
        }

        Image {
            id: icon
            anchors.centerIn: parent
            anchors {
                centerIn: parent
            }
            height: root.adjustedSize
            width: height
            source: root.trayItem?.icon ?? null
        }

        TrayItemMenu {
            id: trayMenu
            parent: root
            visible: false
        }

        onClicked: (event) => onClickedFunction(event)

        function onClickedFunction(mouse: MouseEvent)
        {
            var button = mouse.button
            switch (mouse.button) {
            case Qt.LeftButton: {
                root.trayItem.activate()
                break
            }
            case Qt.RightButton: {
                trayMenu.open()
                break
            }
            case Qt.MiddleButton: {
                root.trayItem.secondaryActivate()
                break
            }

            }
        }
    }

}