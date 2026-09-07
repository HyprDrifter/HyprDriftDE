import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

PopupWindow {
    id: root

    required property var anchorWindow
    required property Item moveToItem

    property bool closing: false
    property real cardOpacity: 0
    property real cardScale: 0.94
    property real cardOffset: -10
    property bool pointerHasEntered: false

    readonly property int hostWidth: Math.max(1,
        Math.round(Number(anchorWindow?.width) || Settings.volumeMixerPreferredWidth))
    readonly property int cardMargin: 14
    readonly property int cardSpacing: 10
    readonly property int applicationCount: AudioControl.applicationStreams.length
    readonly property int applicationContentWidth: applicationCount > 0
        ? applicationCount * Settings.volumeMixerChannelWidth
            + Math.max(0, applicationCount - 1)
                * Settings.volumeMixerChannelSpacing
        : 0
    readonly property int channelContentWidth: cardMargin * 2
        + Settings.volumeMixerSystemChannelWidth
        + (applicationCount > 0
            ? 1 + Settings.volumeMixerSectionSpacing * 2
                + applicationContentWidth
            : 0)
    readonly property int contentPreferredWidth: Math.max(
        Settings.volumeMixerMinimumWidth,
        cardMargin * 2 + headerTitle.implicitWidth,
        channelContentWidth
    )
    readonly property int contentPreferredHeight: cardMargin * 2
        + headerTitle.implicitHeight
        + 1
        + cardSpacing * 2
        + systemChannel.implicitHeight

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
    implicitWidth: Math.min(
        Settings.volumeMixerPreferredWidth,
        hostWidth,
        contentPreferredWidth
    )
    implicitHeight: contentPreferredHeight

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

    onVisibleChanged: {
        if (visible) {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            closing = false
            openAnimation.restart()
        } else {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            openAnimation.stop()
            closeAnimation.stop()
            cardOpacity = 0
            cardScale = 0.94
            cardOffset = -10
            closing = false
        }
    }

    onImplicitWidthChanged: {
        if (visible)
            anchor.updateAnchor()
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
        id: mixerCard

        anchors.fill: parent
        y: root.cardOffset
        opacity: root.cardOpacity
        scale: root.cardScale
        transformOrigin: Item.Top
        radius: 16
        color: Settings.volumeControllerBackgroundColor
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
            anchors.margins: root.cardMargin
            spacing: root.cardSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: headerTitle.implicitHeight

                Text {
                    id: headerTitle

                    Layout.fillWidth: true
                    text: "Volume Mixer"
                    color: Settings.text
                    font.family: Settings.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Settings.surface1
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: systemChannel.implicitHeight
                spacing: Settings.volumeMixerSectionSpacing

                Item {
                    visible: root.applicationCount === 0
                    Layout.fillWidth: true
                }

                MixerChannel {
                    id: systemChannel

                    node: AudioControl.sink
                    master: true
                    Layout.preferredWidth: Settings.volumeMixerSystemChannelWidth
                    Layout.maximumWidth: Settings.volumeMixerSystemChannelWidth
                    Layout.fillHeight: true
                }

                Item {
                    visible: root.applicationCount === 0
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: root.applicationCount > 0
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: Settings.surface1
                }

                Item {
                    visible: root.applicationCount > 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable {
                        id: applicationViewport

                        anchors.fill: parent
                        visible: AudioControl.applicationStreams.length > 0
                        clip: true
                        contentWidth: Math.max(width, applicationRow.implicitWidth)
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick
                        interactive: contentWidth > width

                        RowLayout {
                            id: applicationRow

                            height: applicationViewport.height
                            spacing: Settings.volumeMixerChannelSpacing

                            Repeater {
                                model: ScriptModel {
                                    values: AudioControl.applicationStreams
                                }

                                delegate: MixerChannel {
                                    required property var modelData

                                    node: modelData
                                    Layout.preferredWidth: Settings.volumeMixerChannelWidth
                                    Layout.maximumWidth: Settings.volumeMixerChannelWidth
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        ScrollBar.horizontal: ScrollBar {
                            policy: applicationViewport.contentWidth
                                > applicationViewport.width
                                ? ScrollBar.AsNeeded
                                : ScrollBar.AlwaysOff
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
            from: 0.94
            to: 1
            duration: 210
            easing.type: Easing.OutBack
        }

        NumberAnimation {
            target: root
            property: "cardOffset"
            from: -10
            to: 0
            duration: 180
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
            to: 0.97
            duration: 130
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "cardOffset"
            to: -7
            duration: 130
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
