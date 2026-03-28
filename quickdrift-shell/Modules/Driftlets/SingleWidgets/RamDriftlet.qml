import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Configs.Settings
import qs.Modules.Controls

Rectangle {
    id: ram
    property string usage
    width: 60
    height: ramTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: ramTxt
        text: ram.usage
        anchors.centerIn: parent
    }

    Process {
        id: ramGetData
        command: ["bash", "-c", "bash /etc/hyprdrift/quickdrift/Scripts/Get-RAM-Percent.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: ram.usage = ThemeSettings.ramIcon + " " + this.text.replace(/^\n+|\n+$/g, "") + "G"
        }
    }

    Timer {
        interval: ThemeSettings.ramRefreshRate
        running: true
        repeat: true
        onTriggered: ramGetData.running = true
    }
}
