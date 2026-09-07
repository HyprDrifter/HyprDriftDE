pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.Internal
import qs.Services

PopupWindow {
    id: root

    required property Item moveToItem
    required property var anchorWindow
    required property var output
    required property var group

    property bool pointerHasEntered: false
    property bool allowAnchorOverflow: false
    property bool sideAnchor: false
    signal openRequested()
    signal openCancelled()
    signal windowActionTriggered()

    readonly property var windowRows: group?.windows || []
    readonly property int popupMargin: 10
    readonly property int cardSpacing: 8
    readonly property int availableWidth: Math.max(1,
        Number(output?.width || anchorWindow?.width || 1)
            - Settings.taskbarLeftGap - Settings.taskbarRightGap)
    readonly property int effectiveCardWidth: Math.min(
        Settings.applicationBarPreviewCardWidth,
        Math.max(120, availableWidth - popupMargin * 2))
    readonly property int previewRowWidth: windowRows.length > 0
        ? windowRows.length * effectiveCardWidth
            + Math.max(0, windowRows.length - 1) * cardSpacing
        : effectiveCardWidth

    function requestOpen(): void {
        dismissTimer.stop()
        if (windowRows.length > 0 && !visible) {
            openRequested()
            openTimer.restart()
        }
    }

    function keepOpenFromTrigger(): void {
        dismissTimer.stop()
    }

    function schedulePointerDismiss(): void {
        const pendingOpen = openTimer.running
        openTimer.stop()
        if (pendingOpen && !visible)
            openCancelled()
        if (visible && pointerHasEntered)
            dismissTimer.restart()
    }

    function cancelPointerDismiss(): void {
        pointerHasEntered = true
        dismissTimer.stop()
    }

    function reposition(): void {
        if (visible && moveToItem)
            anchor.updateAnchor()
    }

    function reveal(): void {
        openTimer.stop()
        if (windowRows.length === 0 || !moveToItem) {
            openCancelled()
            return
        }
        visible = true
        anchor.updateAnchor()
    }

    function dismiss(): void {
        const pendingOpen = openTimer.running
        openTimer.stop()
        if (pendingOpen && !visible)
            openCancelled()
        dismissTimer.stop()
        visible = false
    }

    visible: false
    grabFocus: false
    color: "transparent"
    implicitWidth: Math.min(availableWidth,
        popupMargin * 2 + previewRowWidth)
    implicitHeight: popupMargin * 2
        + Settings.applicationBarPreviewCardHeight

    anchor {
        window: root.anchorWindow
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide

        onAnchoring: {
            const buttonRect = root.anchorWindow.itemRect(root.moveToItem)
            if (root.sideAnchor) {
                root.anchor.rect.x = root.anchorWindow.width
                    + Settings.applicationBarPopupGap
                root.anchor.rect.y = Math.round(buttonRect.y)
                return
            }
            const idealX = buttonRect.x + buttonRect.width / 2
                - root.implicitWidth / 2
            const maximumX = Math.max(0,
                root.anchorWindow.width - root.implicitWidth)
            root.anchor.rect.x = root.allowAnchorOverflow
                ? Math.round(idealX)
                : Math.round(Math.max(0, Math.min(idealX, maximumX)))
            root.anchor.rect.y = root.anchorWindow.height
                + Settings.applicationBarPopupGap
        }
    }

    onWindowRowsChanged: {
        if ((visible || openTimer.running) && windowRows.length === 0)
            dismiss()
        else if (visible)
            Qt.callLater(root.reposition)
    }

    onImplicitWidthChanged: {
        if (visible)
            Qt.callLater(root.reposition)
    }

    onImplicitHeightChanged: {
        if (visible)
            Qt.callLater(root.reposition)
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(root.reposition)
        else
            pointerHasEntered = false
    }

    Timer {
        id: openTimer
        interval: Settings.applicationBarPreviewOpenDelay
        repeat: false
        onTriggered: root.reveal()
    }

    Timer {
        id: dismissTimer
        interval: Settings.applicationBarPreviewDismissDelay
        repeat: false
        onTriggered: root.dismiss()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Settings.background
        border.width: 1
        border.color: Settings.surface1
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.cancelPointerDismiss()
                else
                    root.schedulePointerDismiss()
            }
        }

        ListView {
            id: previewList
            anchors.fill: parent
            anchors.margins: root.popupMargin
            orientation: ListView.Horizontal
            spacing: root.cardSpacing
            model: ScriptModel {
                objectProp: "firstSeen"
                values: root.windowRows
            }
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.horizontal: ScrollBar {
                active: previewList.contentWidth > previewList.width
            }

            delegate: Rectangle {
                id: previewCard

                required property var modelData
                readonly property var windowRow: modelData
                readonly property bool windowMinimized:
                    ApplicationWindowModel.revision >= 0
                        && ApplicationWindowModel.isWindowMinimized(
                            windowRow.toplevel)
                readonly property bool windowMaximized:
                    ApplicationWindowModel.revision >= 0
                        && ApplicationWindowModel.isWindowMaximized(
                            windowRow.toplevel)
                readonly property bool showWindowControls:
                    cardPointer.containsMouse
                        || minimizePointer.containsMouse
                        || maximizePointer.containsMouse
                        || closePointer.containsMouse

                width: root.effectiveCardWidth
                height: Settings.applicationBarPreviewCardHeight
                radius: 9
                color: cardPointer.containsMouse
                    ? Settings.surface0
                    : Settings.mantle
                border.width: windowRow.activated ? 2 : 1
                border.color: windowRow.activated
                    ? Settings.blue
                    : Settings.surface1
                clip: true

                ScreencopyView {
                    id: windowPreview
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Settings.applicationBarPreviewImageHeight
                    captureSource: root.visible
                        ? previewCard.windowRow.toplevel
                        : null
                    live: root.visible
                    paintCursor: false
                    constraintSize.width: previewCard.width
                    constraintSize.height: height
                }

                Rectangle {
                    anchors.fill: windowPreview
                    color: Settings.surface0
                    visible: !windowPreview.hasContent

                    IconImage {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        source: root.group?.record
                            ? ApplicationIndex.iconSource(root.group.record)
                            : Quickshell.iconPath("application-x-executable")
                        asynchronous: true
                        mipmap: true
                        opacity: status === Image.Error ? 0 : 1
                    }

                    IconImage {
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        source: Quickshell.iconPath(
                            "application-x-executable")
                        asynchronous: true
                        mipmap: true
                        visible: fallbackIcon.status === Image.Error
                    }
                }

                Rectangle {
                    z: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height
                        - Settings.applicationBarPreviewImageHeight
                    color: Settings.mantle

                    Text {
                        anchors.left: parent.left
                        anchors.right: minimizeWindowButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        text: previewCard.windowRow.title
                        color: Settings.text
                        font.family: Settings.fontFamily
                        font.pixelSize: Math.max(10,
                            Settings.fontPixelSize - 2)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Rectangle {
                        id: minimizeWindowButton
                        anchors.right: maximizeWindowButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 2
                        width: 24
                        height: 24
                        radius: 6
                        color: minimizePointer.containsMouse
                            ? Settings.surface1
                            : "transparent"
                        visible: previewCard.showWindowControls
                        z: 3

                        Accessible.role: Accessible.Button
                        Accessible.name: previewCard.windowMinimized
                            ? qsTr("Restore window")
                            : qsTr("Minimize window")
                        ToolTip.visible: minimizePointer.containsMouse
                        ToolTip.text: Accessible.name

                        Text {
                            anchors.centerIn: parent
                            text: previewCard.windowMinimized ? "↥" : "—"
                            color: Settings.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: minimizePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (ApplicationWindowModel
                                        .toggleWindowMinimized(
                                            previewCard.windowRow.toplevel)) {
                                    root.windowActionTriggered()
                                    root.dismiss()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: maximizeWindowButton
                        anchors.right: closeWindowButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 2
                        width: 24
                        height: 24
                        radius: 6
                        color: maximizePointer.containsMouse
                            ? Settings.surface1
                            : "transparent"
                        visible: previewCard.showWindowControls
                        z: 3

                        Accessible.role: Accessible.Button
                        Accessible.name: previewCard.windowMaximized
                            ? qsTr("Restore window size")
                            : qsTr("Maximize window")
                        ToolTip.visible: maximizePointer.containsMouse
                        ToolTip.text: Accessible.name

                        Text {
                            anchors.centerIn: parent
                            text: previewCard.windowMaximized ? "❐" : "□"
                            color: Settings.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: maximizePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (ApplicationWindowModel
                                        .toggleWindowMaximized(
                                            previewCard.windowRow.toplevel)) {
                                    root.windowActionTriggered()
                                    root.dismiss()
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: closeWindowButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 5
                        width: 24
                        height: 24
                        radius: 6
                        color: closePointer.containsMouse
                            ? Settings.red
                            : "transparent"
                        visible: previewCard.showWindowControls
                        z: 3

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Close window")
                        ToolTip.visible: closePointer.containsMouse
                        ToolTip.text: Accessible.name

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: Settings.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: closePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ApplicationWindowModel.closeWindow(
                                    previewCard.windowRow.toplevel)
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardPointer
                    z: 1
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ApplicationWindowModel.activateWindow(
                            previewCard.windowRow.toplevel)
                        root.windowActionTriggered()
                        root.dismiss()
                    }
                }
            }
        }
    }
}
