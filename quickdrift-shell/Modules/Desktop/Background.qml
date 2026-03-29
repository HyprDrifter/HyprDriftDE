import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

import qs.Configs


Rectangle {
    width: 10
    height: 10
    color: "transparent"
    z: -100
    anchors.fill: parent
    Image {
        z: -100
        source: Qt.resolvedUrl("../../Configs/Themeing/Wallpapers/Catppucino/astronaut.png")
        anchors.fill:parent
        //implicitWidth: parent.width
        //implicitHeight: parent.height
    }
}
