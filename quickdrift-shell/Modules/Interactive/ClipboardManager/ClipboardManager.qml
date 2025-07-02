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
    implicitHeight: 1
    implicitWidth: 500
    anchor.item: moveToItem
    anchor.rect.x: (-implicitWidth / 2) + moveToItem.width / 2
    anchor.rect.y: moveToItem.height - 1
    color: "transparent"
    anchor.edges: Edges.Bottom | Edges.Right


    Item{
        id: recRec
        anchors.fill: parent
    

        states: State {
            name: "opened"; when: clipPopup.visible
            PropertyChanges {target:clipPopup; implicitHeight: 500;}
        }

        transitions: Transition {
            NumberAnimation { 
                properties:"implicitHeight"
                duration: 400
                //easing.overshoot: 1
                easing.type: Easing.OutBack

            }
        }
        
        Rectangle {
            id: clipRectangle
            color: Settings.clipmanPopupBackground
            anchors.fill: parent

            radius: 16
            ColumnLayout {
                id: columnLayout
                spacing: 5
                anchors {
                    fill: parent
                }
                ListView {
                    id: copyRepeater
                    model: ClipboardHistory.entries.data
                    spacing: 15
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.width
                    topMargin: 20
                    
                    // ScrollIndicator.vertical: ScrollIndicator {
                    //     active: true
                    // }

                    delegate: ClipboardEntry {
                        id: option
                        clipManager: clipPopup
                    }
                }
            }
        }
    }
}
