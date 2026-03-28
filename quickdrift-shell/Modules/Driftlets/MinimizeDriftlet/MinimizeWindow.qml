import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.Configs
import qs.Modules.Driftlets.MinimizeDriftlet

PanelWindow {
    id: root

    color: "transparent"

    visible: GlobalStates.minimizeManagerVisible
    implicitHeight: minimizedDisplay.implicitHeight
    implicitWidth: minimizedDisplay.implicitWidth

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false;
        }
    }

    HyprlandFocusGrab {
        id: grab
        windows: [root]

        onCleared: {
            GlobalStates.minimizeManagerVisible = false;
        }
    }

    onVisibleChanged: {
        if (visible) {
            grab.active = true;

            Qt.callLater(() => {
                minimizedDisplay.forceActiveFocus();
            })
        }
    }

    WrapperRectangle {
        id: minimizedDisplay
        focus: true
        color: "#3a000000"
        anchors.fill: parent
        GridLayout {
            id: grid
            columns: 4

            Repeater {
                id: gridRepeater
                model: MinimizeManager.minimizedWindows
                delegate: MinimizeItem { }
            }
        }
    }
}
