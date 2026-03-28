import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Configs.Settings
import qs.Modules.Controls

Item {
    id: root
    Layout.fillHeight: true
    property PanelWindow bar: null
    implicitWidth: container.implicitWidth + 15
    implicitHeight: bar ? bar.height : 40
    anchors.leftMargin: 15

    property int current: Hyprland.focusedWorkspace.id
    property var workspaces: Hyprland.workspaces

    RowLayout {
        id: container
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: 10
        }
        implicitHeight: parent.height
        spacing: 10

        Repeater {
            model: Hyprland.workspaces

            delegate: Button {
                id: delegateButton

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 550
                        easing.type: Easing.OutBack
                        easing.overshoot: delegateButton.implicitWidth / 3
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 550
                        easing.type: Easing.OutBack
                        easing.overshoot: delegateButton.implicitWidth / 3
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                        easing.overshoot: delegateButton.implicitWidth / 3
                    }
                }

                visible: modelData.id >= 0
                implicitHeight: visible ? txt.implicitHeight + 5 : 0
                implicitWidth: visible && modelData.id === root.current ? txt.implicitHeight + 20 : visible ? txt.implicitHeight + 5 : 0
                Layout.minimumWidth: txt.implicitWidth * 1.5

                background: Rectangle {
                    id: background
                    anchors.fill: parent
                    implicitHeight: parent.height
                    implicitWidth: parent.implicitWidth
                    radius: 8
                    color: delegateButton.hovered ? ThemeSettings.workspaceManagerButtonHover : "transparent"
                    opacity: delegateButton.hovered ? 1.0 : 0.4
                    border.color: ThemeSettings.workspaceManagerButtonBorderColor
                    border.width: 0.5
                }

                StyledText {
                    id: txt
                    anchors.centerIn: parent
                    text: modelData && modelData.id !== undefined ? modelData.id : "-"
                }

                onClicked: {
                    console.log("Clicked workspace " + modelData.id);
                    if (modelData && modelData.activate) {
                        modelData.activate();
                    }
                }

                MouseArea {
                    anchors.centerIn: delegateButton
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
