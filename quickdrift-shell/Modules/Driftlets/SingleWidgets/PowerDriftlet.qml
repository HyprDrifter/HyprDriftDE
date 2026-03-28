import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.Configs.Settings
import qs.Modules.Controls

Button {
    id: shutdownButton
    Layout.fillHeight: true
    Layout.preferredWidth: 20
    background: Rectangle {
        id: back
        anchors.centerIn: parent
        width: buttonText.implicitWidth + 2
        height: parent.height - 10
        color: "transparent"
        StyledText {
            id: buttonText
            anchors.centerIn: parent
            family: "FontAwesome"
            pixelSize: shutdownButton.height
            text: "⏻"

            dropShadowHoffset: !shutdownButton.hovered ? ThemeSettings.fontDropShadowHoffset : 0
            dropShadowVoffset: !shutdownButton.hovered ? ThemeSettings.fontDropShadowVoffset : 0
            dropShadowRadius: !shutdownButton.hovered ? ThemeSettings.fontDropShadowRadius : ThemeSettings.fontDropShadowRadius * 2
            dropShadowColor: !shutdownButton.hovered ? ThemeSettings.fontDropShadowColor : "brown"
        }
    }

    onClicked: Qt.createQmlObject(
        'import Quickshell.Io; Process { command: ["wlogout", "-b 6 -r 0 -c 0 -T 0 -B 0 -L 0 -R 0 -p layer-shell"]; running: true }',
        shutdownButton,
        "DynamicProcess"
    );
}
