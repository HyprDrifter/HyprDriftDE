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

    function logTrayItem(prefix, item, index) {
        console.log(
            "[SysTray] " + prefix,
            "index=" + index,
            "id=" + (item?.id ?? ""),
            "title=" + (item?.title ?? ""),
            "status=" + (item?.status ?? ""),
            "icon=" + (item?.icon ?? "")
        )
    }

    implicitWidth: rowLayout.implicitWidth + 8 // padding
    implicitHeight: parent.height * .75
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillHeight: true
    Layout.fillWidth: true

    Component.onCompleted: {
        const items = SystemTray.items.values
        console.log("[SysTray] initialized count=" + items.length)

        for (let index = 0; index < items.length; index++)
            root.logTrayItem("existing item", items[index], index)
    }

    Connections {
        target: SystemTray.items

        function onObjectInsertedPost(object, index) {
            root.logTrayItem("item added", object, index)
        }
    }

    
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
