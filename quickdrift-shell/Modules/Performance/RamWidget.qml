import QtQuick
import qs.Internal
import qs.Services

Rectangle {
    id: ram
    property string usage: SystemMetrics.ramUsedGiB < 0
        ? Settings.ramIcon + " --G"
        : Settings.ramIcon + " " + SystemMetrics.ramUsedGiB.toFixed(1) + "G"
    width: 60
    height: ramTxt.implicitHeight
    color: "transparent"

    StyledText {
        id: ramTxt
        text: ram.usage
        anchors.centerIn: parent
    }
}
