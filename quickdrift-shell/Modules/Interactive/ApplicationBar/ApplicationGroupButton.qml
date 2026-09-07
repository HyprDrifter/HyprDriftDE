pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.Internal
import qs.Services

Item {
    id: root

    required property var group
    required property int modelIndex
    required property var applicationBar
    required property var hostWindow
    required property var output
    property int orientation: Qt.Horizontal

    property bool dragging: false
    property bool suppressClick: false
    property real pressCoordinate: 0
    property real dragOffset: 0
    property int dragTargetIndex: modelIndex

    readonly property bool popupVisible: previewPopup.visible
        || contextMenu.visible

    width: Settings.applicationBarSlotSize
    height: Settings.applicationBarSlotSize
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: group.name
    Accessible.description: group.running
        ? group.windowCount + " open window"
            + (group.windowCount === 1 ? "" : "s")
        : "Pinned application"

    function primaryAction(): void {
        applicationBar.dismiss()
        if (group.running)
            ApplicationWindowModel.activateMostRecent(group)
        else
            ApplicationWindowModel.launchGroup(group)
    }

    function newWindow(): void {
        applicationBar.dismiss()
        ApplicationWindowModel.launchGroup(group)
    }

    function beginPreview(): void {
        if (dragging || !group.running)
            return
        applicationBar.requestPreview(group.modelKey)
        previewPopup.requestOpen()
    }

    function showContextMenu(): void {
        // The context menu owns its focus grab, as it did before preview
        // coordination was added. Let the preview's grab finish clearing
        // before mapping the independently focused menu.
        applicationBar.activePreviewKey = ""
        previewPopup.dismiss()
        Qt.callLater(() => {
            applicationBar.requestContextMenu(group.modelKey)
            contextMenu.reveal()
        })
    }

    Connections {
        target: root.applicationBar

        function onActivePreviewKeyChanged(): void {
            if (root.applicationBar.activePreviewKey !== root.group.modelKey)
                previewPopup.dismiss()
        }

        function onActiveContextKeyChanged(): void {
            if (root.applicationBar.activeContextKey !== root.group.modelKey)
                contextMenu.dismiss()
        }
    }

    Rectangle {
        id: buttonSurface
        x: root.orientation === Qt.Horizontal ? root.dragOffset : 0
        y: root.orientation === Qt.Vertical ? root.dragOffset : 0
        width: Settings.applicationBarSlotSize
        height: Settings.applicationBarSlotSize
        radius: 7
        color: root.group.active
            ? Settings.surface0
            : pointer.containsMouse || root.activeFocus || root.popupVisible
                ? Settings.mantle
                : "transparent"
        opacity: root.dragging ? 0.78 : 1
        scale: root.dragging ? 1.08 : 1

        Behavior on x {
            enabled: !root.dragging
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            enabled: !root.dragging
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on scale {
            NumberAnimation { duration: 100 }
        }

        Item {
            anchors.centerIn: parent
            width: Settings.applicationBarIconSize
            height: Settings.applicationBarIconSize

            IconImage {
                id: applicationIcon
                anchors.fill: parent
                source: root.group?.record
                    ? ApplicationIndex.iconSource(root.group.record)
                    : Quickshell.iconPath("application-x-executable")
                asynchronous: true
                mipmap: true
                opacity: status === Image.Error ? 0 : 1
            }

            IconImage {
                anchors.fill: parent
                source: Quickshell.iconPath("application-x-executable")
                asynchronous: true
                mipmap: true
                visible: applicationIcon.status === Image.Error
            }
        }

        Rectangle {
            x: root.orientation === Qt.Vertical
                ? parent.width - width - 1
                : (parent.width - width) / 2
            y: root.orientation === Qt.Vertical
                ? (parent.height - height) / 2
                : parent.height - height - 1
            width: root.orientation === Qt.Vertical
                ? 2
                : root.group.active ? 16 : 10
            height: root.orientation === Qt.Vertical
                ? root.group.active ? 16 : 10
                : 2
            radius: 1
            color: root.group.active ? Settings.blue : Settings.lavender
            visible: root.group.running

            Behavior on width {
                NumberAnimation { duration: 120 }
            }

            Behavior on height {
                NumberAnimation { duration: 120 }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.rightMargin: 1
            width: 12
            height: 12
            radius: 6
            color: Settings.blue
            visible: root.group.windowCount > 1

            Text {
                anchors.centerIn: parent
                text: root.group.windowCount > 9
                    ? "9+"
                    : String(root.group.windowCount)
                color: Settings.background
                font.family: Settings.fontFamily
                font.pixelSize: root.group.windowCount > 9 ? 7 : 8
                font.bold: true
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        preventStealing: root.group.pinned
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            previewPopup.keepOpenFromTrigger()
            root.beginPreview()
        }

        onExited: previewPopup.schedulePointerDismiss()

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton || !root.group.pinned)
                return
            root.pressCoordinate = root.orientation === Qt.Vertical
                ? mouse.y
                : mouse.x
            root.dragOffset = 0
            root.dragTargetIndex = root.modelIndex
            root.suppressClick = false
        }

        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton) || !root.group.pinned)
                return

            const coordinate = root.orientation === Qt.Vertical
                ? mouse.y
                : mouse.x
            const offset = coordinate - root.pressCoordinate
            if (!root.dragging && Math.abs(offset) >= 6) {
                root.dragging = true
                previewPopup.dismiss()
                root.applicationBar.dismissAllPopups()
            }
            if (!root.dragging)
                return

            root.dragOffset = offset
            const stride = Settings.applicationBarSlotSize
                + Settings.applicationBarItemSpacing
            const position = root.orientation === Qt.Vertical
                ? root.y + mouse.y
                : root.x + mouse.x
            root.dragTargetIndex = Math.max(0, Math.min(
                Math.floor(position / stride),
                root.applicationBar.pinnedGroupCount - 1))
        }

        onReleased: mouse => {
            if (!root.dragging)
                return

            root.suppressClick = true
            root.dragging = false
            root.dragOffset = 0
            ApplicationBarStore.movePin(
                root.group.desktopId, root.dragTargetIndex)
            Qt.callLater(() => root.suppressClick = false)
        }

        onCanceled: {
            root.dragging = false
            root.dragOffset = 0
            root.suppressClick = false
        }

        onClicked: mouse => {
            if (root.suppressClick)
                return
            if (mouse.button === Qt.RightButton)
                root.showContextMenu()
            else if (mouse.button === Qt.MiddleButton)
                root.newWindow()
            else
                root.primaryAction()
        }

        onWheel: wheel => {
            root.applicationBar.scrollBy(wheel.angleDelta.y)
            wheel.accepted = true
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.primaryAction()
            event.accepted = true
        } else if (event.key === Qt.Key_Menu) {
            root.showContextMenu()
            event.accepted = true
        }
    }

    ApplicationPreviewPopup {
        id: previewPopup
        moveToItem: root
        anchorWindow: root.hostWindow
        output: root.output
        group: root.group
        allowAnchorOverflow: false
        sideAnchor: root.orientation === Qt.Vertical

        onOpenRequested: root.applicationBar.registerAuxiliaryWindow(
            previewPopup)
        onOpenCancelled: root.applicationBar.releaseAuxiliaryWindow(
            previewPopup)
        onWindowActionTriggered: root.applicationBar.dismiss()

        onVisibleChanged: {
            if (visible) {
                root.applicationBar.registerAuxiliaryWindow(previewPopup)
            } else {
                root.applicationBar.releaseAuxiliaryWindow(previewPopup)
                if (root.applicationBar.activePreviewKey
                        === root.group.modelKey)
                    root.applicationBar.activePreviewKey = ""
            }
        }
    }

    ApplicationContextMenu {
        id: contextMenu
        moveToItem: root
        anchorWindow: root.hostWindow
        output: root.output
        group: root.group
        applicationBar: root.applicationBar
        manageFocusGrab: true
        allowAnchorOverflow: true
        sideAnchor: root.orientation === Qt.Vertical

        onVisibleChanged: {
            if (!visible && root.applicationBar.activeContextKey
                    === root.group.modelKey)
                root.applicationBar.activeContextKey = ""
        }
    }
}
