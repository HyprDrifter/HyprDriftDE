pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    required property var hostWindow
    required property var output
    required property string outputKey

    property string activePreviewKey: ""
    property string activeContextKey: ""
    property var activeAuxiliaryWindows: []

    readonly property var groups: ApplicationWindowModel.groups
    readonly property int pinnedGroupCount: groups.filter(
        group => group.pinned === true).length
    readonly property real contentWidth: groups.length > 0
        ? groups.length * Settings.applicationBarSlotSize
            + Math.max(0, groups.length - 1)
                * Settings.applicationBarItemSpacing
        : 0

    visible: groups.length > 0
    objectName: "application-bar-" + outputKey
    implicitWidth: Math.min(
        Settings.applicationBarMaximumWidth, contentWidth)
    implicitHeight: Settings.taskbarHeight
    Layout.minimumWidth: visible ? Settings.applicationBarSlotSize : 0
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: Settings.applicationBarMaximumWidth
    Layout.preferredHeight: implicitHeight

    function dismiss(): void {
        dismissAllPopups()
    }

    function dismissPreviews(): void {
        activePreviewKey = ""
        activeAuxiliaryWindows = []
    }

    function requestPreview(groupKey): void {
        activeContextKey = ""
        activePreviewKey = groupKey
    }

    function requestContextMenu(groupKey): void {
        activePreviewKey = ""
        activeContextKey = groupKey
    }

    function dismissAllPopups(): void {
        activePreviewKey = ""
        activeContextKey = ""
        activeAuxiliaryWindows = []
    }

    function registerAuxiliaryWindow(window): void {
        if (!window || activeAuxiliaryWindows.includes(window))
            return
        activeAuxiliaryWindows = activeAuxiliaryWindows.concat([window])
    }

    function releaseAuxiliaryWindow(window): void {
        activeAuxiliaryWindows = activeAuxiliaryWindows.filter(
            candidate => candidate !== window)
    }

    function scrollBy(verticalDelta): void {
        if (applicationList.contentWidth <= applicationList.width)
            return
        const amount = verticalDelta > 0
            ? -Settings.applicationBarSlotSize * 2
            : Settings.applicationBarSlotSize * 2
        applicationList.contentX = Math.max(0, Math.min(
            applicationList.contentX + amount,
            applicationList.contentWidth - applicationList.width))
    }

    onGroupsChanged: {
        if (activePreviewKey.length > 0
                && !groups.some(group =>
                    group.modelKey === activePreviewKey))
            activePreviewKey = ""
        if (activeContextKey.length > 0
                && !groups.some(group => group.modelKey === activeContextKey))
            activeContextKey = ""
    }

    HyprlandFocusGrab {
        active: root.activeAuxiliaryWindows.length > 0
        windows: [root.hostWindow].concat(root.activeAuxiliaryWindows)

        onCleared: root.dismissPreviews()
    }

    ListView {
        id: applicationList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Settings.applicationBarSlotSize
        orientation: ListView.Horizontal
        spacing: Settings.applicationBarItemSpacing
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            objectProp: "modelKey"
            values: root.groups
        }

        delegate: ApplicationGroupButton {
            required property int index
            required property var modelData

            group: modelData
            modelIndex: index
            applicationBar: root
            hostWindow: root.hostWindow
            output: root.output
            orientation: Qt.Horizontal
        }

        WheelHandler {
            onWheel: event => {
                root.scrollBy(event.angleDelta.y)
                event.accepted = true
            }
        }
    }

}
