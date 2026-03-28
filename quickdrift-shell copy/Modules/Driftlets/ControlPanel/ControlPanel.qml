import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls.SpinBoxs
import qs.Modules.Controls.Buttons

PopupWindow {
    id: root

    required property Item parent
    property int taskbarGap: Settings.taskbar.margins.popupGap
    property point anchorPoint: Qt.point(parent.x, parent.y)

    color: "transparent"
    anchor.item: parent
    anchor.rect.x: 0 - root.width + parent.width + parent.horPad + parent.horPad
    anchor.rect.y: (anchorPoint.y + root.height + taskbarGap) * -1
    visible: false
    implicitWidth: 500
    implicitHeight: 500

    HyprlandFocusGrab {
        id: fcsGrbr
        windows: [root]
        onCleared: {
            root.swapStates();
        }
    }

    Rectangle {
        id: content
        radius: Settings.taskbar.geometry.radius
        transitions: Transition {
            NumberAnimation {
                properties: "implicitHeight"
                duration: root.implicitHeight / 1.5
                easing.type: Easing.OutQuint
            }
            onRunningChanged: {
                if (running && content.state == "opened") {
                    root.visible = true;
                } else if (!running && content.state == "closed") {
                    root.visible = false;
                }
            }
        }

        state: "closed"
        color: ThemeSettings.clipmanPopupBackground
        implicitWidth: 500
        implicitHeight: 1

        anchors {
            bottom: parent.bottom
        }

        states: [
            State {
                name: "opened"
                PropertyChanges {
                    content.implicitHeight: 500
                    fcsGrbr.active: true
                }
                //PropertyChanges { root.visible: true}
            },
            State {
                name: "closed"
                PropertyChanges {
                    content.implicitHeight: 1
                    fcsGrbr.active: false
                }
            }
        ]
    }

    function swapStates() {
        if (content.state == "closed") {
            content.state = "opened";
        } else {
            content.state = "closed";
        }
    }
}
