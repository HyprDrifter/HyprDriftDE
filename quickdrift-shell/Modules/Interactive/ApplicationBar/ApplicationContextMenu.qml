pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
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
    required property var applicationBar
    property bool manageFocusGrab: true
    property bool allowAnchorOverflow: false
    property bool sideAnchor: false

    readonly property int currentStoreRevision: ApplicationBarStore.revision
    readonly property bool groupPinned: ApplicationBarStore.isPinned(
        group?.desktopId || "")
    readonly property var menuItems: {
        const revision = currentStoreRevision
        const desktopId = String(group?.desktopId || "")
        const running = group?.running === true
        const count = Number(group?.windowCount || 0)
        const items = [
            {
                id: "pin",
                label: groupPinned ? "Unpin from application bar"
                    : "Pin to application bar",
                enabled: desktopId.length > 0
            },
            {
                id: "new",
                label: "New window",
                enabled: desktopId.length > 0
                    && group?.available === true
            },
            {
                id: "close",
                label: count > 1 ? "Close most recent window"
                    : "Close window",
                enabled: running
            }
        ]
        if (count > 1) {
            items.push({
                id: "close-all",
                label: "Close all windows",
                enabled: true
            })
        }
        return items
    }

    function reveal(): void {
        visible = true
        anchor.updateAnchor()
    }

    function dismiss(): void {
        visible = false
    }

    function runAction(actionId): void {
        if (actionId === "pin") {
            if (groupPinned)
                ApplicationBarStore.unpin(group.desktopId)
            else
                ApplicationBarStore.pin(group.desktopId)
        } else if (actionId === "new") {
            ApplicationWindowModel.launchGroup(group)
        } else if (actionId === "close") {
            ApplicationWindowModel.closeMostRecent(group)
        } else if (actionId === "close-all") {
            ApplicationWindowModel.closeGroup(group)
        }
        dismiss()
        applicationBar.dismiss()
    }

    visible: false
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(Settings.applicationBarContextMenuWidth,
        Math.max(1, Number(output?.width || anchorWindow?.width || 1)))
    implicitHeight: 12 * 2
        + menuItems.length * Settings.applicationBarContextMenuRowHeight
        + Math.max(0, menuItems.length - 1) * 3

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

    onVisibleChanged: {
        if (visible) {
            anchor.updateAnchor()
            Qt.callLater(() => menuCard.forceActiveFocus())
        }
    }

    HyprlandFocusGrab {
        active: root.visible && root.manageFocusGrab
        windows: [root]
        onCleared: root.dismiss()
    }

    Rectangle {
        id: menuCard
        anchors.fill: parent
        anchors.margins: 0
        focus: true
        radius: 11
        color: Settings.background
        border.width: 1
        border.color: Settings.surface1

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss()
                event.accepted = true
            }
        }

        Column {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: 12
            spacing: 3

            Repeater {
                model: ScriptModel {
                    objectProp: "id"
                    values: root.menuItems
                }

                delegate: Button {
                    id: menuButton
                    required property var modelData

                    width: menuColumn.width
                    height: Settings.applicationBarContextMenuRowHeight
                    enabled: modelData.enabled === true
                    focusPolicy: Qt.NoFocus
                    onClicked: root.runAction(modelData.id)

                    background: Rectangle {
                        radius: 7
                        color: menuButton.hovered
                            ? Settings.surface0
                            : "transparent"
                    }

                    contentItem: Text {
                        text: menuButton.modelData.label
                        color: menuButton.enabled
                            ? Settings.text
                            : Settings.surface2
                        font.family: Settings.fontFamily
                        font.pixelSize: Math.max(10,
                            Settings.fontPixelSize - 1)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
