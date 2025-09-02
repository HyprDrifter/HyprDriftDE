import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Services
import qs.Services.IconResolver
import qs.Internal
import qs.Modules.Interactive.ClipboardManager

// TODO: More fancy animation
Item {
    id: root

    required property var bar

    implicitWidth: rowLayout.implicitWidth + 8 // padding
    implicitHeight: parent.height * .75
    Layout.preferredWidth: implicitWidth 
    Layout.preferredHeight: implicitHeight
    Layout.fillHeight: true
    Layout.fillWidth: true

    
    //Layout.leftMargin: Appearance.rounding.screenRounding
    WrapperRectangle{
        radius: 8
        border.width: Settings.taskbarTrayEnableBorder ? Settings.taskbarTrayBorderWidth : 0
        border.color: Settings.taskbarTrayBorderColor
        color: "transparent"
        anchors.fill: parent
        anchors{
            topMargin: Settings.taskbarTrayPadding
            bottomMargin: Settings.taskbarTrayPadding
        }

        
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 2
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 4
                rightMargin: 4
            }

            Repeater {
                id: trayRepeater
                model: SystemTray.items
                Layout.fillWidth: true
                Layout.fillHeight: true
                delegate: SysTrayItem {
                    required property SystemTrayItem modelData
                    bar: root.bar
                    item: modelData
                }
            }
        }

    }

}
