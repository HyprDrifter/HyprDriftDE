import QtQuick
import qs.Internal
import qs.Services

Rectangle {
    id: gpu
    property string usage: SystemMetrics.gpuUsage < 0
        ? Settings.gpuIcon + " --%"
        : Settings.gpuIcon + " " + Math.round(SystemMetrics.gpuUsage) + "%"
    width: 60
    height: gpuTxt.implicitHeight
    color: "transparent"
    
    StyledText {
        id: gpuTxt
        text: gpu.usage
        anchors.centerIn: parent
    }
}
