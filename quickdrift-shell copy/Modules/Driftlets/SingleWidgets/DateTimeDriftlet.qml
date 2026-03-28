import QtQuick
import QtQuick.Layouts

import qs.Configs.Settings

Rectangle {
    id: root
    color: "transparent"

    Layout.preferredWidth: clockText.implicitWidth
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignVCenter
    
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    

    Text {
        id: clockText
        
        anchors.centerIn: parent
        text: ThemeSettings.clockDisplay
        color: ThemeSettings.fontColor
    }
}
