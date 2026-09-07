import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Internal
import qs.Services
import qs.Modules.Interactive.VolumeController

Item {
    id: root
    required property var bar
    readonly property int volumePercent: AudioControl.currentVolume
    readonly property bool muted: AudioControl.muted

    width: 60
    height: 30

    StyledText {
        id: volumeText
        anchors.centerIn: parent
        text: muted || volumePercent <= 0 ?  "\uf6a9 " + volumePercent + "%" :
              volumePercent < 33 ? "\uf026 " + volumePercent + "%" :
              volumePercent < 75 ? "\uf027 " + volumePercent + "%" :
                                   "\uf028 " + volumePercent + "%"
        pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: vFlyout.cancelPointerDismiss()
        onExited: vFlyout.schedulePointerDismiss()
        onClicked: vFlyout.toggle()

        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y > 0
                ? Settings.audioVolumeStep
                : -Settings.audioVolumeStep
            AudioControl.adjustMasterVolume(delta)
        }

    }

    VolumeFlyout {
        id: vFlyout
        anchorWindow: root.bar
        moveToItem: root
    }
}
