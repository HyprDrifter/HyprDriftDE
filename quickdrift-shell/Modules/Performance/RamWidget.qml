import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:Internal/"

Rectangle {
    id: ram    
    property string usage
    width: 60
    height: ramTxt.implicitHeight
    //Layout.preferredWidth: 45
    //Layout.preferredHeight: ramTxt.implicitHeight
    //Layout.alignment: horizontalCenter
    color: "transparent"

    StyledText {
        id: ramTxt
        text: ram.usage
        anchors.centerIn: parent
    }

    
    Process {
        id: ramGetData
        command: ["bash", "-c", "bash $HOME/.config/quickshell/Desktop/Scripts/Get-RAM-Percent.sh"]
        running: true
        
        stdout: StdioCollector {
        onStreamFinished: ram.usage = Settings.ramIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "G"
        }
    }

    Timer {
        interval: Settings.ramRefreshRate
        running: true
        repeat: true
        onTriggered: ramGetData.running = true
    }
}
