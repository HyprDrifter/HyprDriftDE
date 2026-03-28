import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets
import qs.Configs.Settings
import qs.Modules.Controls

Item {
    id: activeWindowDisplay
    property var bar: null
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: windowText.implicitHeight
    Layout.preferredWidth: windowText.implicitWidth

    StyledTextLarge {
        id: windowText
        implicitWidth: bar ? Math.min(activeWindowDisplay.parent.width, bar.width / 3) : activeWindowDisplay.parent?.width ?? 200
        text: activeWindow?.activated ? activeWindow.title : qsTr("Desktop")
        txt.clip: true
        txt.wrapMode: Text.NoWrap
    }
}
