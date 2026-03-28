import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Configs.Settings
import qs.Modules.Controls

Rectangle {
    id: cpu
    property string usage
    width: 60
    height: cpuTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: cpuTxt
        text: cpu.usage
        anchors.centerIn: parent
    }

    Process {
        id: cpuGetData
        command: ["bash", "-c", "bash /etc/hyprdrift/quickdrift/Scripts/Get-CPU-Percent.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: cpu.usage = ThemeSettings.cpuIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "%"
        }
    }

    Timer {
        interval: ThemeSettings.cpuRefreshRate
        running: true
        repeat: true
        onTriggered: cpuGetData.running = true
    }
}
