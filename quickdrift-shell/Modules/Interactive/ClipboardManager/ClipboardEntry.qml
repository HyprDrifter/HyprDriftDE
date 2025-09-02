import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Internal

Item {
    id: entryItem
    required property int id
    required property string summary
    required property var clipManager
    anchors.horizontalCenter: parent.horizontalCenter
    implicitWidth: clipManager.implicitWidth * .9
    implicitHeight : textItem.height
    anchors.topMargin: 15
    anchors.bottomMargin: 15
    
    focus: true

    

    // Rectangle{
    //     anchors.fill: parent
    //     color: "brown"
    // }

    Button{
        id: button
        implicitHeight: textItem.implicitHeight + 10
        implicitWidth: parent.implicitWidth
        anchors.centerIn: parent
        
        background: Rectangle {
            radius: 8
            color: parent.hovered ? Settings.clipmanPopupButtonBackgroundHover : Settings.clipmanPopupButtonBackground
        }
        
        StyledText {
            id: textItem
            width: parent.width
            implicitHeight: txt.implicitHeight + 10
            text: entryItem.summary
            txt.width: textItem.width - 20
            txt.horizontalAlignment: Text.AlignHCenter
        }

        onClicked: {
            console.log("Click to Copy")
            ClipboardHistory.copy(id)
            clipManager.visible = false
        }
    }
}
