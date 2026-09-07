pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

PopupWindow {
    id: root

    required property Item moveToItem
    required property var anchorWindow

    property bool pointerHasEntered: false
    property bool editorOpen: false
    property string editingId: ""
    property string executingId: ""
    property string completedId: ""
    property string executionStatusPath: ""
    property int executionSerial: 0

    property alias draftLabel: labelField.text
    property alias draftIcon: iconField.text
    property alias draftCommand: commandField.text

    readonly property int cardMargin: 14
    readonly property int contentSpacing: 10
    readonly property int actionCount: QuickActionsStore.actions.length
    readonly property int listContentHeight: actionCount > 0
        ? actionCount * Settings.quickActionsRowHeight
            + Math.max(0, actionCount - 1) * actionList.spacing
        : 0
    readonly property int editorHeight: editorOpen
        ? editorCard.implicitHeight + contentSpacing
        : 0
    readonly property int fixedContentHeight: cardMargin * 2
        + headerRow.implicitHeight
        + editorHeight
        + (actionCount > 0 ? contentSpacing : 0)
    readonly property int availableListHeight: Math.max(0,
        Settings.quickActionsPopupMaxHeight - fixedContentHeight)
    readonly property int listViewportHeight: Math.min(
        listContentHeight, availableListHeight)
    readonly property bool draftValid: draftLabel.trim().length > 0
        && draftCommand.trim().length > 0
    readonly property int hostWidth: Math.max(1,
        Math.round(Number(anchorWindow?.width)
            || Settings.quickActionsPopupWidth))

    function reveal(): void {
        hoverDismissTimer.stop()
        if (!visible)
            visible = true
    }

    function dismiss(): void {
        hoverDismissTimer.stop()
        completedId = ""
        visible = false
    }

    function toggle(): void {
        if (visible)
            dismiss()
        else
            reveal()
    }

    function cancelPointerDismiss(): void {
        pointerHasEntered = true
        hoverDismissTimer.stop()
    }

    function schedulePointerDismiss(): void {
        if (visible && pointerHasEntered)
            hoverDismissTimer.restart()
    }

    function beginAdd(): void {
        editingId = ""
        draftLabel = ""
        draftIcon = ""
        draftCommand = ""
        editorOpen = true
        Qt.callLater(() => labelField.forceActiveFocus())
    }

    function beginEdit(action): void {
        if (!action)
            return

        editingId = String(action.id)
        draftLabel = String(action.label)
        draftIcon = String(action.icon || "")
        draftCommand = String(action.command)
        editorOpen = true
        Qt.callLater(() => labelField.forceActiveFocus())
    }

    function cancelEdit(): void {
        editorOpen = false
        editingId = ""
        draftLabel = ""
        draftIcon = ""
        draftCommand = ""
    }

    function saveDraft(): void {
        if (!draftValid)
            return

        if (editingId.length > 0) {
            QuickActionsStore.updateAction(
                editingId, draftLabel, draftIcon, draftCommand)
            cancelEdit()
            return
        }

        if (QuickActionsStore.addAction(
                draftLabel, draftIcon, draftCommand))
            cancelEdit()
    }

    function deleteAction(action): void {
        if (!action)
            return
        if (editingId === String(action.id))
            cancelEdit()
        QuickActionsStore.removeAction(action.id)
    }

    function runAction(action): void {
        if (!action || executionProbe.running
                || executionProbeTimer.running
                || executingId.length > 0)
            return

        completedId = ""
        executionSerial += 1
        executionStatusPath = Quickshell.cachePath(
            "quick-action-result-" + Date.now()
                + "-" + executionSerial)
        executingId = String(action.id)

        if (!QuickActionsStore.runAction(
                action.id, executionStatusPath)) {
            executingId = ""
            executionStatusPath = ""
            return
        }

        executionProbe.command = [
            "/usr/bin/test",
            "-f",
            executionStatusPath
        ]
        executionProbeTimer.restart()
    }

    function finishExecution(): void {
        const finishedId = executingId
        const finishedPath = executionStatusPath

        executionProbeTimer.stop()
        executingId = ""
        executionStatusPath = ""
        completedId = visible ? finishedId : ""

        if (finishedPath.length > 0) {
            Quickshell.execDetached([
                "/usr/bin/rm",
                "-f",
                "--",
                finishedPath
            ])
        }
    }

    visible: false
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(Settings.quickActionsPopupWidth, hostWidth)
    implicitHeight: Math.min(
        Settings.quickActionsPopupMaxHeight,
        fixedContentHeight + listViewportHeight)

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
            root.anchor.rect.y = root.anchorWindow.height
                + Settings.quickActionsPopupGap
        }
    }

    onVisibleChanged: {
        hoverDismissTimer.stop()
        pointerHasEntered = false
        if (!visible)
            completedId = ""
        if (visible) {
            Qt.callLater(() => {
                if (root.editorOpen)
                    labelField.forceActiveFocus()
                else
                    addButton.forceActiveFocus()
            })
        }
    }

    onImplicitWidthChanged: {
        if (visible)
            anchor.updateAnchor()
    }

    onImplicitHeightChanged: {
        if (visible)
            anchor.updateAnchor()
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]

        onCleared: {
            if (root.visible)
                root.dismiss()
        }
    }

    ScriptModel {
        id: actionModel
        objectProp: "id"
        values: QuickActionsStore.actions
    }

    Rectangle {
        id: popupCard
        anchors.fill: parent
        radius: 14
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.cardMargin
            spacing: root.contentSpacing

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Quick Actions"
                    color: Settings.text
                    font.family: Settings.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                }

                Button {
                    id: addButton
                    text: "Add"
                    enabled: !root.editorOpen
                    implicitWidth: 62
                    implicitHeight: 30
                    Accessible.name: "Add quick action"
                    onClicked: root.beginAdd()

                    contentItem: Text {
                        text: addButton.text
                        color: addButton.enabled
                            ? Settings.text
                            : Settings.surface2
                        font.family: Settings.fontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: addButton.down
                            ? Settings.surface1
                            : addButton.hovered || addButton.activeFocus
                                ? Settings.surface0
                                : Settings.mantle
                        border.width: addButton.activeFocus ? 1 : 0
                        border.color: Settings.blue
                    }
                }
            }

            Rectangle {
                id: editorCard
                visible: root.editorOpen
                Layout.fillWidth: true
                implicitHeight: editorLayout.implicitHeight + 20
                radius: 10
                color: Settings.mantle
                border.width: 1
                border.color: Settings.surface1

                ColumnLayout {
                    id: editorLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    TextField {
                        id: labelField
                        Layout.fillWidth: true
                        implicitHeight: 36
                        placeholderText: "Label"
                        color: Settings.text
                        placeholderTextColor: Settings.rosewater
                        font.family: Settings.fontFamily
                        font.pixelSize: 13
                        selectByMouse: true

                        background: Rectangle {
                            radius: 7
                            color: Settings.background
                            border.width: labelField.activeFocus ? 1 : 0
                            border.color: Settings.blue
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: iconField
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "Theme icon name (optional)"
                            color: Settings.text
                            placeholderTextColor: Settings.rosewater
                            font.family: Settings.fontFamily
                            font.pixelSize: 12
                            selectByMouse: true

                            background: Rectangle {
                                radius: 7
                                color: Settings.background
                                border.width: iconField.activeFocus ? 1 : 0
                                border.color: Settings.blue
                            }
                        }

                        IconImage {
                            id: previewIcon
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: QuickActionsStore.iconSource({
                                icon: root.draftIcon
                            })
                            asynchronous: true
                            mipmap: true
                            visible: String(source).length > 0
                                && status !== Image.Error
                        }

                        StyledText {
                            visible: String(previewIcon.source).length === 0
                                || previewIcon.status === Image.Error
                            text: Settings.quickActionsIcon
                            pixelSize: 14
                            fontColor: Settings.rosewater
                        }
                    }

                    TextArea {
                        id: commandField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        placeholderText: "Command"
                        color: Settings.text
                        placeholderTextColor: Settings.rosewater
                        font.family: Settings.fontFamily
                        font.pixelSize: 12
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap

                        background: Rectangle {
                            radius: 7
                            color: Settings.background
                            border.width: commandField.activeFocus ? 1 : 0
                            border.color: Settings.blue
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Button {
                            id: cancelButton
                            text: "Cancel"
                            implicitWidth: 72
                            implicitHeight: 30
                            onClicked: root.cancelEdit()

                            contentItem: Text {
                                text: cancelButton.text
                                color: Settings.rosewater
                                font.family: Settings.fontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 8
                                color: cancelButton.down
                                    ? Settings.surface1
                                    : cancelButton.hovered
                                            || cancelButton.activeFocus
                                        ? Settings.surface0
                                        : "transparent"
                                border.width: cancelButton.activeFocus ? 1 : 0
                                border.color: Settings.blue
                            }
                        }

                        Button {
                            id: saveButton
                            text: root.editingId.length > 0 ? "Save" : "Add"
                            enabled: root.draftValid
                            implicitWidth: 72
                            implicitHeight: 30
                            onClicked: root.saveDraft()

                            contentItem: Text {
                                text: saveButton.text
                                color: saveButton.enabled
                                    ? Settings.text
                                    : Settings.surface2
                                font.family: Settings.fontFamily
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 8
                                color: saveButton.down
                                    ? Settings.surface1
                                    : saveButton.hovered
                                            || saveButton.activeFocus
                                        ? Settings.surface0
                                        : Settings.mantle
                                border.width: saveButton.activeFocus ? 1 : 0
                                border.color: Settings.blue
                            }
                        }
                    }
                }
            }

            ListView {
                id: actionList
                visible: root.actionCount > 0
                Layout.fillWidth: true
                Layout.preferredHeight: root.listViewportHeight
                model: actionModel
                spacing: 7
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: actionList.contentHeight > actionList.height
                        ? ScrollBar.AsNeeded
                        : ScrollBar.AlwaysOff
                }

                delegate: Rectangle {
                    id: actionCard

                    required property int index
                    required property var modelData

                    width: actionList.width
                    height: Settings.quickActionsRowHeight
                    radius: 9
                    color: Settings.mantle
                    border.width: 1
                    border.color: Settings.surface1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 1

                        Button {
                            id: runButton
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: root.executingId.length === 0
                            focusPolicy: Qt.TabFocus
                            Accessible.name: "Run " + actionCard.modelData.label
                            onClicked: root.runAction(actionCard.modelData)

                            contentItem: RowLayout {
                                spacing: 9

                                Item {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22

                                    IconImage {
                                        id: actionIcon
                                        anchors.centerIn: parent
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        source: QuickActionsStore.iconSource(
                                            actionCard.modelData)
                                        asynchronous: true
                                        mipmap: true
                                        visible: root.executingId
                                                !== String(actionCard.modelData.id)
                                            && root.completedId
                                                !== String(actionCard.modelData.id)
                                            && String(source).length > 0
                                            && status !== Image.Error
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: root.executingId
                                                !== String(actionCard.modelData.id)
                                            && root.completedId
                                                !== String(actionCard.modelData.id)
                                            && (String(actionIcon.source).length === 0
                                                || actionIcon.status
                                                    === Image.Error)
                                        text: Settings.quickActionsIcon
                                        pixelSize: 14
                                        fontColor: Settings.rosewater
                                    }

                                    StyledText {
                                        id: executionSpinner
                                        anchors.centerIn: parent
                                        visible: root.executingId
                                            === String(actionCard.modelData.id)
                                        text: ""
                                        pixelSize: 15
                                        fontColor: Settings.blue

                                        RotationAnimator on rotation {
                                            running: executionSpinner.visible
                                            from: 0
                                            to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                        }
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: root.completedId
                                            === String(actionCard.modelData.id)
                                        text: "󰄬"
                                        pixelSize: 16
                                        fontColor: Settings.green
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: actionCard.modelData.label
                                    color: Settings.text
                                    font.family: Settings.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            background: Rectangle {
                                radius: 7
                                color: runButton.down
                                    ? Settings.surface1
                                    : runButton.hovered
                                            || runButton.activeFocus
                                        ? Settings.surface0
                                        : "transparent"
                                border.width: runButton.activeFocus ? 1 : 0
                                border.color: Settings.blue
                            }
                        }

                        CardControl {
                            text: "✎"
                            Accessible.name: "Edit "
                                + actionCard.modelData.label
                            onClicked: root.beginEdit(actionCard.modelData)
                        }

                        CardControl {
                            text: "↑"
                            enabled: actionCard.index > 0
                            Accessible.name: "Move "
                                + actionCard.modelData.label + " up"
                            onClicked: QuickActionsStore.moveAction(
                                actionCard.modelData.id,
                                actionCard.index - 1)
                        }

                        CardControl {
                            text: "↓"
                            enabled: actionCard.index
                                < root.actionCount - 1
                            Accessible.name: "Move "
                                + actionCard.modelData.label + " down"
                            onClicked: QuickActionsStore.moveAction(
                                actionCard.modelData.id,
                                actionCard.index + 1)
                        }

                        CardControl {
                            text: ""
                            iconColor: enabled ? Settings.red : Settings.surface2
                            Accessible.name: "Delete "
                                + actionCard.modelData.label
                            onClicked: root.deleteAction(actionCard.modelData)
                        }
                    }
                }
            }
        }
    }

    component CardControl: Button {
        id: control

        property color iconColor: enabled
            ? Settings.rosewater
            : Settings.surface2

        implicitWidth: 22
        implicitHeight: 30
        focusPolicy: Qt.TabFocus

        contentItem: Text {
            text: control.text
            color: control.iconColor
            font.family: Settings.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 6
            color: control.down
                ? Settings.surface1
                : control.hovered || control.activeFocus
                    ? Settings.surface0
                    : "transparent"
            border.width: control.activeFocus ? 1 : 0
            border.color: Settings.blue
        }
    }

    Timer {
        id: hoverDismissTimer
        interval: 180
        repeat: false
        onTriggered: root.dismiss()
    }

    Process {
        id: executionProbe

        onExited: (exitCode, exitStatus) => {
            if (root.executionStatusPath.length === 0)
                return
            if (exitCode === 0)
                root.finishExecution()
            else
                executionProbeTimer.restart()
        }
    }

    Timer {
        id: executionProbeTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.executionStatusPath.length > 0
                    && !executionProbe.running)
                executionProbe.running = true
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.dismiss()
    }
}
