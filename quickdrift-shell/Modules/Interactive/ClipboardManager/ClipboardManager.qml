import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import "root:/Modules/Interactive/ClipboardManager"
import "root:/Internal"

PopupWindow {
    id: clipPopup

    required property var moveToItem
    property bool animateNext: true
    visible: false
    height: 10
    width: 10
    anchor.item: moveToItem
    anchor.rect.x: implicitWidth / 2 + moveToItem.width
    anchor.rect.y: moveToItem.height
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left;
    
    color: "transparent"

    onVisibleChanged: {
        if(visible)
        {
            height = 500
            width = 400
        }
        else{
            height = 10
            width = 10
        }
    }

    Behavior on height { SmoothedAnimation { duration: 200; velocity: 200 } }
    Behavior on width { SmoothedAnimation { duration: 200; velocity: 200 } }

    Item{
        id: recRec
        anchors.fill: parent

        Rectangle {
            id: clipRectangle
            color: Settings.clipmanPopupBackground
            anchors.fill: parent
            implicitHeight: 500
            radius: 16

            ColumnLayout {
                id: columnLayout
                spacing: 5
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    fill: parent
                }

                ListView {
                    id: copyRepeater
                    model: ClipboardHistory.entries.data
                    spacing: 15
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.width
                    topMargin: 20
                    
                    ScrollIndicator.vertical: ScrollIndicator {
                        active: true
                    }

                    delegate: ClipboardEntry {
                        id: option
                        clipManager: clipPopup
                    }
                }
            }
        }
    }
}
