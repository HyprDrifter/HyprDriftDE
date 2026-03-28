// WorkspaceManager.qml
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Internal

Item {
    id: root
    Layout.fillHeight: true
    //Layout.fillWidth: true
    required property PanelWindow bar
    implicitWidth: container.implicitWidth + 15
    implicitHeight: bar.height
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
        //implicitWidth: parent.width
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
                    color: delegateButton.hovered ? Settings.workspaceManagerButtonHover : "transparent" // frappe highlight/inactive
                    opacity: delegateButton.hovered ? 1.0 : 0.4
                    border.color: Settings.workspaceManagerButtonBorderColor
                    border.width: modelData.id === root.current ? .5 : .5
                }

                StyledText {
                    id: txt
                    anchors.centerIn: parent
                    text: modelData && modelData.id !== undefined ? modelData.id : "-"
                }

                onClicked: {
                    console.log("Clicked");
                    console.log(`Length of workspaces : ${Hyprland.workspaces.length}`);
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

        onStateChanged: {
            console.log();
        }
    }
}
