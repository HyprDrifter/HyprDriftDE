import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "root:Internal"
import "root:/Services"
import "root:/Modules/Interactive/VolumeController"

Item {
    id: root
    required property var bar
    property int volumePercent: AudioControl.currentVolume
    property var audioSink: AudioControl.sink.audio

    width: 60
    height: 30

    StyledText {
        id: volumeText
        anchors.centerIn: parent
        text: volumePercent <= 0 ?  "\uf6a9 " + volumePercent + "%" :
              volumePercent < 33 ? "\uf026 " + volumePercent + "%" :
              volumePercent < 75 ? "\uf027 " + volumePercent + "%" :
                                   "\uf028 " + volumePercent + "%"
        pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            //Hyprland.dispatch("exec pavucontrol")
            vFlyout.visible = !vFlyout.visible
        }

        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            audioSink.volume = Math.max(0, audioSink.volume + delta); // no upper clamp
        }

    }

    VolumeFlyout {
        id: vFlyout
        anchorWindow: root.bar
        moveToItem: root
    }
}
