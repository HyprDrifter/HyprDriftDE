import QtQuick
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    required property var hostWindow

    implicitWidth: 28
    implicitHeight: Settings.taskbarHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: "Quick actions"
    Accessible.description: "Open custom quick actions"

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: pointer.containsMouse || root.activeFocus || menu.visible
            ? Settings.mantle
            : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: Settings.quickActionsIcon
        pixelSize: 16
        fontColor: menu.visible ? Settings.yellow : Settings.fontColor
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: menu.cancelPointerDismiss()
        onExited: menu.schedulePointerDismiss()
        onClicked: menu.toggle()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            menu.toggle()
            event.accepted = true
        }
    }

    QuickActionsMenu {
        id: menu
        moveToItem: root
        anchorWindow: root.hostWindow
    }
}
