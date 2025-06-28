import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:Internal/"

Rectangle {
    id: gpu    
    property string usage
    width: 60
    height: gpuTxt.implicitHeight
    //Layout.preferredWidth: 65
    //Layout.preferredHeight: gpuTxt.implicitHeight
    color: "transparent"
    
    StyledText {
        id: gpuTxt
        text: gpu.usage
        anchors.centerIn: parent
    }
    
    Process {
        id: gpuGetData
        command: ["bash", "-c", "bash $HOME/.config/quickshell/Desktop/Scripts/Get-GPU-Percent.sh"]
        running: true
        
        stdout: StdioCollector {
        onStreamFinished: gpu.usage = Settings.gpuIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "%"
        }
    }

    Timer {
        interval: Settings.gpuRefreshRate
        running: true
        repeat: true
        onTriggered: gpuGetData.running = true
    }
}
