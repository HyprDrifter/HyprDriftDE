import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Controls
import "root:/Services/"
import "root:/Services/IconResolver"
import "root:/Internal"

MouseArea {
    id: root
    required property var bar
    required property SystemTrayItem item

    property string resolvedIcon: IconOverrideStore.overrides[item.id] || item.icon
    property bool targetMenuOpen: false
    property int trayItemWidth: Settings.taskbarTrayIconPreferedWidth

    implicitWidth: trayItemWidth + 4  // buffer for margin/padding
    implicitHeight: trayItemWidth + 4

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    Button {
        id: hoverBackground
        anchors.fill: parent
        background: Rectangle {
            id: shader
            color: hoverBackground.hovered ? Settings.surface2 : "transparent"
            radius: 100
            implicitHeight: root.trayItemWidth + 5
            implicitWidth: root.trayItemWidth + 5
            anchors.centerIn: parent
        }
    }

    onClicked: event => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu)
                menu.open();
            break;
        }
        event.accepted = true;
    }

    QsMenuAnchor {
        id: menu
        menu: root.item.menu
        anchor.item: root
        anchor.rect.x: -50
        anchor.rect.height: root.height
        anchor.edges: Edges.Bottom
    }

    IconImage {
        id: trayIcon
        source: root.resolvedIcon
        anchors.centerIn: parent
        width: root.trayItemWidth
        height: parent.height
        visible: true
    }

    Connections {
        target: IconOverrideStore
        function onOverrideChanged(id) {
            if (id === item.id) {
                root.resolvedIcon = "";
                root.resolvedIcon = IconOverrideStore.overrides[item.id] || item.icon;
            }
        }
    }
}

