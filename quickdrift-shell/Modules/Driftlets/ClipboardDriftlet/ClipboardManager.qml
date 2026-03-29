import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Configs
import qs.Configs.Settings
import qs.Modules.Driftlets.ClipboardDriftlet

PopupWindow {
    id: root

    required property Item parent
    property int taskbarGap: Settings.taskbar.margins.popupGap
    property point anchorPoint: Qt.point(parent.x, parent.y)

    color: "transparent"
    anchor.item: parent
    anchor.rect.x: 0 - root.implicitWidth + parent.width
    anchor.rect.y: (anchorPoint.y + root.implicitHeight + taskbarGap) * -1
    visible: false
    implicitWidth: 400
    implicitHeight: 500
    mask: Region { item: clipContent }

    HyprlandFocusGrab {
        id: grabber
        windows: [root]
        onCleared: root.swapStates()
    }

    Rectangle {
        id: clipContent
        color: ThemeSettings.clipmanPopupBackground
        radius: Settings.taskbar.geometry.radius
        clip: true
        state: "closed"
        implicitWidth: 400
        implicitHeight: 1
        anchors.bottom: parent.bottom

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 333
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    if (!running && clipContent.state == "closed") {
                        root.visible = false
                    }
                }
            }
        }

        states: [
            State {
                name: "opened"
                PropertyChanges {
                    clipContent.implicitHeight: 500
                    grabber.active: true
                }
            },
            State {
                name: "closed"
                PropertyChanges {
                    clipContent.implicitHeight: 1
                    grabber.active: false
                }
            }
        ]

        ListView {
            id: clipList
            anchors {
                fill: parent
                margins: 8
                topMargin: 12
            }
            model: ClipboardHistory.clipboardData
            spacing: 8
            clip: true

            ScrollIndicator.vertical: ScrollIndicator {
                active: true
            }

            delegate: ClipboardEntry {
                clipManager: root
            }
        }
    }

    function swapStates() {
        if (clipContent.state == "closed") {
            root.visible = true
            clipContent.state = "opened"
        } else {
            clipContent.state = "closed"
        }
    }
}
