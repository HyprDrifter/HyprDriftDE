import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Configs.Settings
import qs.Modules.Controls

Rectangle {
    id: gpu
    property string usage
    width: 60
    height: gpuTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: gpuTxt
        text: gpu.usage
        anchors.centerIn: parent
    }

    Process {
        id: gpuGetData
        command: ["bash", "-c", "bash /etc/hyprdrift/quickdrift/Scripts/Get-GPU-Percent.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: gpu.usage = ThemeSettings.gpuIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "%"
        }
    }

    Timer {
        interval: ThemeSettings.gpuRefreshRate
        running: true
        repeat: true
        onTriggered: gpuGetData.running = true
    }
}
