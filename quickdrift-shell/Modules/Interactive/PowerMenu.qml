pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal

PopupWindow {
    id: root

    required property Item moveToItem
    required property var anchorWindow
    property bool pointerHasEntered: false
    readonly property string powerScript: Quickshell.env("HOME")
        + "/.config/hypr/scripts/power.sh"

    readonly property var actions: [
        {
            label: "Lock",
            icon: "",
            command: ["/usr/bin/bash", powerScript, "lock"]
        },
        {
            label: "Logout",
            icon: "󰍃",
            command: ["/usr/bin/bash", powerScript, "exit"]
        },
        {
            label: "Suspend",
            icon: "",
            command: ["/usr/bin/bash", powerScript, "suspend"]
        },
        {
            label: "Hibernate",
            icon: "",
            command: ["/usr/bin/bash", powerScript, "hibernate"]
        },
        {
            label: "Shutdown",
            icon: "",
            command: ["/usr/bin/bash", powerScript, "shutdown"]
        },
        {
            label: "Reboot",
            icon: "",
            command: ["/usr/bin/bash", powerScript, "reboot"]
        }
    ]

    function reveal(): void {
        hoverDismissTimer.stop()
        visible = true
    }

    function dismiss(): void {
        hoverDismissTimer.stop()
        visible = false
    }

    function cancelPointerDismiss(): void {
        pointerHasEntered = true
        hoverDismissTimer.stop()
    }

    function schedulePointerDismiss(): void {
        if (visible && pointerHasEntered)
            hoverDismissTimer.restart()
    }

    function toggle(): void {
        if (visible)
            dismiss()
        else
            reveal()
    }

    function runAction(command): void {
        dismiss()
        Quickshell.execDetached(command)
    }

    visible: false
    grabFocus: true
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 286

    onVisibleChanged: {
        hoverDismissTimer.stop()
        pointerHasEntered = false
    }

    anchor {
        window: root.anchorWindow
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide

        onAnchoring: {
            const buttonRect = root.anchorWindow.itemRect(root.moveToItem)
            const idealX = buttonRect.x + buttonRect.width / 2
                - root.implicitWidth / 2
            const maximumX = Math.max(0,
                root.anchorWindow.width - root.implicitWidth)

            root.anchor.rect.x = Math.round(Math.max(0,
                Math.min(idealX, maximumX)))
            root.anchor.rect.y = root.anchorWindow.height + 15
        }
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]

        onCleared: {
            if (root.visible)
                root.dismiss()
        }
    }

    Rectangle {
        id: powerCard

        anchors.fill: parent
        radius: 14
        color: Settings.background
        border.width: 1
        border.color: Settings.surface1

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.cancelPointerDismiss()
                else
                    root.schedulePointerDismiss()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26

                Text {
                    text: "Power"
                    color: Settings.text
                    font.family: Settings.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.actions

                    delegate: Button {
                        id: actionButton

                        required property var modelData

                        text: modelData.label
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Accessible.name: modelData.label
                        onClicked: root.runAction(modelData.command)

                        background: Rectangle {
                            radius: 10
                            color: actionButton.down
                                ? Settings.surface1
                                : actionButton.hovered || actionButton.activeFocus
                                    ? Settings.surface0
                                    : Settings.mantle
                            border.width: actionButton.activeFocus ? 1 : 0
                            border.color: Settings.blue
                        }

                        contentItem: ColumnLayout {
                            spacing: 4

                            Text {
                                text: actionButton.modelData.icon
                                color: actionButton.modelData.label === "Shutdown"
                                    ? Settings.red
                                    : Settings.lavender
                                font.family: Settings.fontFamily
                                font.pixelSize: 25
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Text {
                                text: actionButton.modelData.label
                                color: Settings.text
                                font.family: Settings.fontFamily
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hoverDismissTimer

        interval: 180
        repeat: false
        onTriggered: root.dismiss()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.dismiss()
    }
}
