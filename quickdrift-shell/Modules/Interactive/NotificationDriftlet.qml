import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    required property var bar

    readonly property string statusText: {
        if (!NotificationController.available)
            return "Notification center is starting"
        if (NotificationController.count === 0)
            return "No notifications"
        if (NotificationController.count === 1)
            return "1 notification"
        return NotificationController.count + " notifications"
    }

    function buttonCenterOnOutput(): int {
        const scenePosition = root.mapToItem(null, root.width / 2, 0)
        return Math.round(Settings.taskbarLeftGap + scenePosition.x)
    }

    function toggleControlCenter(): void {
        const scenePosition = root.mapToItem(null, 0, 0)
        NotificationController.toggleControlCenter(
            root.buttonCenterOnOutput(),
            Math.round(root.bar.screen.width),
            Math.round(root.bar.screen.x + Settings.taskbarLeftGap
                + scenePosition.x),
            Math.round(root.bar.screen.y + Settings.taskbarTopGap
                + scenePosition.y),
            Math.round(root.width),
            Math.round(root.height)
        )
    }

    implicitWidth: 28
    implicitHeight: Settings.taskbarHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: statusText
    Accessible.description: "Open notification history; middle click clears all notifications"

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: pointer.containsMouse
                || root.activeFocus
                || NotificationController.controlCenterVisible
            ? Settings.mantle
            : "transparent"
    }

    StyledText {
        anchors.centerIn: parent
        text: NotificationController.doNotDisturb
            ? Settings.notificationDisabledIcon
            : Settings.notificationIcon
        pixelSize: 16
        fontColor: NotificationController.inhibited
            ? Settings.yellow
            : Settings.fontColor
    }

    Rectangle {
        visible: NotificationController.count > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.rightMargin: -2
        implicitWidth: Math.max(12, badgeText.implicitWidth + 5)
        implicitHeight: 12
        radius: height / 2
        color: Settings.red

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: NotificationController.count > 50
                ? "50+"
                : String(NotificationController.count)
            color: Settings.base00
            font.family: Settings.fontFamily
            font.pixelSize: 8
            font.bold: true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                NotificationController.clearAll()
            else
                root.toggleControlCenter()
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.toggleControlCenter()
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            NotificationController.clearAll()
            event.accepted = true
        }
    }
}
