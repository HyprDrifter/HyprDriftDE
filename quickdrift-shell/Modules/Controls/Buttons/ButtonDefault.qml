import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Configs.Settings

Button {
    id: root

    property string textContent: ""
    property color backgroundColor: hovered ? ThemeSettings.buttons.backgroundColorHovered : ThemeSettings.buttons.backgroundColor
    property color borderColor: hovered ? ThemeSettings.buttons.backgroundColor : ThemeSettings.buttons.backgroundColorHovered
    property int borderWidth: 0
    property int textSize: ThemeSettings.fontPixelSize
    default property alias content: layout.data
    padding: 0

    background: Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
        implicitHeight: root.textSize * 2
        //implicitWidth: btnText.implicitWidth * 1.5

        Behavior on color {
            ColorAnimation {
                duration: 333
                easing.type: Easing.OutQuint
            }
        }

        border {
            id: buttonBorder

            width: root.borderWidth
            color: root.borderColor
        }

        RowLayout {
            id: layout

            anchors.fill: parent

            Text {
                id: btnText
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: ThemeSettings.fontColor
                font.pixelSize: root.textSize
                text: root.textContent
            }
        }
    }
}
