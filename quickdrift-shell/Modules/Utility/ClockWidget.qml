import QtQuick
import QtQuick.Layouts
import "root:Internal/"

Rectangle {
    id: root
    color: "transparent"
    width: clockText.implicitWidth
    height: clockText.implicitHeight
    //Layout.preferredWidth: clockText.implicitWidth
    //Layout.preferredHeight: clockText.implicitHeight

    StyledText {
        id: clockText
        anchors.fill: root
        text: Settings.clockDisplay
    }
}
