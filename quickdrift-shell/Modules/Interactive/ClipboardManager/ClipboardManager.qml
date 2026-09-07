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

    property bool closing: false
    property real cardOpacity: 0
    property real cardScale: 0.92
    property real cardOffset: -12
    property bool pointerHasEntered: false

    function reveal(): void {
        hoverDismissTimer.stop()

        if (visible && !closing)
            return
        closing = false
        visible = true
    }

    function dismiss(): void {
        if (!visible || closing)
            return
        hoverDismissTimer.stop()
        closing = true
        closeAnimation.restart()
    }

    function cancelPointerDismiss(): void {
        pointerHasEntered = true
        hoverDismissTimer.stop()
    }

    function schedulePointerDismiss(): void {
        if (visible && !closing && pointerHasEntered)
            hoverDismissTimer.restart()
    }

    function toggle(): void {
        if (visible)
            dismiss()
        else
            reveal()
    }

    visible: false
    grabFocus: true
    color: "transparent"
    implicitWidth: 430
    implicitHeight: 540

    anchor.item: moveToItem
    anchor.rect.x: Math.round((moveToItem.width - implicitWidth) / 2)
    anchor.rect.y: moveToItem.height + 15
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.All

    onVisibleChanged: {
        if (visible) {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            closing = false
            ClipboardHistory.refresh()
            openAnimation.restart()
        } else {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            openAnimation.stop()
            closeAnimation.stop()
            cardOpacity = 0
            cardScale = 0.92
            cardOffset = -12
            closing = false
        }
    }

    HyprlandFocusGrab {
        active: root.visible && !root.closing
        windows: [root]

        onCleared: {
            if (root.visible && !root.closing)
                root.dismiss()
        }
    }

    Rectangle {
        id: popupCard
        width: parent.width
        height: parent.height
        y: root.cardOffset
        opacity: root.cardOpacity
        scale: root.cardScale
        transformOrigin: Item.Top
        radius: 14
        color: Settings.clipmanPopupBackground
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
                Layout.preferredHeight: 32
                spacing: 8

                Text {
                    text: "Clipboard"
                    color: Settings.text
                    font.family: Settings.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                }

                Text {
                    text: ClipboardHistory.count + " / " + ClipboardHistory.historyLimit
                    color: Settings.rosewater
                    font.family: Settings.fontFamily
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                Button {
                    id: clearButton
                    text: ClipboardHistory.clearing
                        ? "Clearing…"
                        : ClipboardHistory.pinnedCount > 0
                            ? "Clear Unpinned"
                            : "Clear All"
                    enabled: ClipboardHistory.count > 0
                        && !ClipboardHistory.clearing
                        && !ClipboardHistory.pinBusy
                    implicitHeight: 30
                    onClicked: ClipboardHistory.clearAll()

                    contentItem: Text {
                        text: clearButton.text
                        color: clearButton.enabled ? Settings.text : Settings.surface2
                        font.family: Settings.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: clearButton.hovered ? Settings.surface1 : Settings.surface0
                    }
                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: ClipboardHistory.loaded && ClipboardHistory.count === 0
                    text: "Clipboard history is empty"
                    color: Settings.rosewater
                    font.family: Settings.fontFamily
                    font.pixelSize: 13
                }

                ListView {
                    id: historyList
                    anchors.fill: parent
                    visible: ClipboardHistory.count > 0
                    model: ClipboardHistory.entries.data
                    spacing: 8
                    clip: true
                    topMargin: 2
                    bottomMargin: 2
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: ClipboardEntry {
                        required property var modelData

                        clipId: String(modelData.clipId)
                        summary: String(modelData.summary)
                        isImage: modelData.isImage === true
                        clipManager: root
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

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 0
            to: 1
            duration: 170
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "cardScale"
            from: 0.92
            to: 1
            duration: 220
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: root
            property: "cardOffset"
            from: -12
            to: 0
            duration: 190
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "cardOpacity"
            to: 0
            duration: 120
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "cardScale"
            to: 0.96
            duration: 140
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "cardOffset"
            to: -8
            duration: 140
            easing.type: Easing.InCubic
        }

        onStopped: {
            if (root.closing)
                root.visible = false
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.dismiss()
    }
}
