import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:Internal/"

Rectangle {
    id: cpu    
    property string usage
    width: 60
    height: cpuTxt.implicitHeight
    //Layout.preferredWidth: 45
    //Layout.preferredHeight: cpuTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: cpuTxt
        text: cpu.usage
        anchors.centerIn: parent
    }

    
    Process {
        id: cpuGetData
        command: ["bash", "-c", "bash $HOME/.config/quickshell/Desktop/Scripts/Get-CPU-Percent.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: cpu.usage = Settings.cpuIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "%"
        }
    }


    Timer {
        interval: Settings.cpuRefreshRate
        running: true
        repeat: true
        onTriggered: cpuGetData.running = true
    }
}
