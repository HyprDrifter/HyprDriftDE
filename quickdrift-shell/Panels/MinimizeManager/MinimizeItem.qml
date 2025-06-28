import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "root:/Modules/Interactive"
import "root:/Modules/Interactive/ApplicationLauncher"
import "root:/Internal"
import "root:/Services"
import "root:/Panels/MinimizeManager"

WrapperRectangle {
    id: root

    required property string address 
    required property string title
    required property var topLevel
    property string holder
    property var currentScreenSize: [{height: Hyprland.focusedMonitor.height, width: Hyprland.focusedMonitor.width}]
    //property var toplevelList: ToplevelManager.toplevels.values

    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth

    color: "transparent"
    
    ColumnLayout{
        id: layout
        anchors.fill: parent
        implicitHeight: displayTitle.implicitHeight
        implicitWidth: displayTitle.implicitWidth
        StyledText {
                id: displayTitle
                Layout.maximumWidth: windowPreview.implicitWidth - 20
                Layout.maximumHeight: txt.implicitHeight
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: txt.height
                implicitWidth: windowPreview.implicitWidth - 20
                //anchors.centerIn: parent

                text: root.title
                txt.width: displayTitle.width

            }
        Button{
            id: windRestoreButton
            implicitWidth: 300
            implicitHeight: 300

            background: ScreencopyView
            {
                id: windowPreview
                anchors.fill: parent
                captureSource: root.topLevel
                live: Settings.minimizerLivePreview
                constraintSize.height:300
                constraintSize.width:300
            }



            onClicked: {
                console.log("CLICKED THE THING : " + root.title)
                MinimizeManager.restoreSelectedFunction(root.address)
                for (let i = 0; i < MinimizeManager.minimizedWindows.count; i++) {
                    if (MinimizeManager.minimizedWindows.get(i).address === root.address) {
                        MinimizeManager.minimizedWindows.remove(i, 1)
                        break
                    }
                }
                GlobalVariables.minimizeManagerVisible = false
            }
            
        }
        
        
        

    }
    
}