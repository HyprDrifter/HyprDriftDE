import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets
import qs.Internal

Item {
    id: activeWindowDisplay
    required property var bar
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    // Layout.fillHeight: true
    // Layout.fillWidth: true
    //anchors.fill: bar
    anchors.horizontalCenter: bar.horizontalCenter
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: windowText.implicitHeight
    Layout.preferredWidth: windowText.implicitWidth

    StyledTextLarge{ 

        id: windowText
        implicitWidth: Math.min(activeWindowDisplay.parent.width, bar.width / 3)
        text: activeWindow?.activated ? activeWindow.title : qsTr("Desktop")
        txt.clip: true
        txt.wrapMode: Text.NoWrap
    }

}