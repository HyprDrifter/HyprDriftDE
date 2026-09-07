import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import qs.Internal

Item {
    id: activeWindowDisplay
    required property var bar
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    implicitWidth: Math.min(windowText.implicitWidth, bar.width / 3)
    implicitHeight: Settings.taskbarHeight
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: true
    Layout.minimumWidth: Settings.applicationBarTitleMinimumWidth
    Layout.maximumWidth: bar.width / 3
    Layout.preferredHeight: implicitHeight

    Text {
        id: windowText
        anchors.fill: parent
        text: activeWindowDisplay.activeWindow
                && activeWindowDisplay.activeWindow.activated
            ? activeWindowDisplay.activeWindow.title
            : qsTr("Desktop")
        color: Settings.fontColor
        font.family: Settings.fontFamily
        font.pixelSize: Settings.fontLargePixelsize
        font.weight: Settings.fontWeight
        font.bold: Settings.fontBold
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        clip: true
    }
}
