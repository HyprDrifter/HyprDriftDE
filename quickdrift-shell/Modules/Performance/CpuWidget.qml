import QtQuick
import qs.Internal
import qs.Services

Rectangle {
    id: cpu
    property string usage: SystemMetrics.cpuUsage < 0
        ? Settings.cpuIcon + " --%"
        : Settings.cpuIcon + " " + Math.round(SystemMetrics.cpuUsage) + "%"
    width: 60
    height: cpuTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: cpuTxt
        text: cpu.usage
        anchors.centerIn: parent
    }
}
