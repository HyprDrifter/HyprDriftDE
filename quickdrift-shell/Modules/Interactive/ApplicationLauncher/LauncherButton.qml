import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Hyprland
import qs.Internal
import qs.Services
import qs.Modules.Interactive
import qs.Modules.Interactive.ApplicationLauncher

Button {
    id: launcherBtn
    //Layout.fillHeight: true
    Layout.preferredWidth: height
    Layout.preferredHeight: parent.height

    background: Rectangle {
        id: backgroundRectangle
        anchors {
            fill: launcherBtn
            centerIn: launcherBtn
            topMargin: 3
            bottomMargin: 3
        }
        //color: "transparent"
        color: parent.hovered ? Settings.rosewater : "transparent"
        width: height
        radius: 8

        StyledText {
            id: icontext
            text: Settings.applaunchIconText  // FontAwesome launcher icon
            anchors.centerIn: backgroundRectangle
            Layout.fillWidth: true
            Layout.fillHeight: true
            pixelSize: launcherBtn.height / 2
            //fontColor: "#f2d5cf"
        }

        MouseArea {
            id: archMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            
        }

    }

    onClicked: {
        //Hyprland.dispatch("exec wofi --show drun" )
        GlobalVariables.launcherOpen = !GlobalVariables.launcherOpen;
    }



}
