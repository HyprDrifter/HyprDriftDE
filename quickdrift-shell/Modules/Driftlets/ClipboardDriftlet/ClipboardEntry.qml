import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Configs.Settings
import qs.Modules.Controls
import qs.Modules.Driftlets.ClipboardDriftlet

Item {
    id: entryItem
    required property int id
    required property string summary
    required property var clipManager
    anchors.horizontalCenter: parent.horizontalCenter
    implicitWidth: clipManager.implicitWidth * .9
    implicitHeight: textItem.height
    anchors.topMargin: 15
    anchors.bottomMargin: 15

    focus: true

    Button {
        id: button
        implicitHeight: textItem.implicitHeight + 10
        implicitWidth: parent.implicitWidth
        anchors.centerIn: parent

        background: Rectangle {
            radius: 8
            color: parent.hovered ? ThemeSettings.clipmanPopupButtonBackgroundHover : ThemeSettings.clipmanPopupButtonBackground
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
            console.log("Clipboard entry clicked, copying id: " + entryItem.id)
            ClipboardHistory.copy(id)
            clipManager.visible = false
        }
    }
}
