import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Internal
import qs.Services
import qs.Modules.Interactive.VolumeController

PopupWindow {
    id: root

    required property var anchorWindow
    required property var moveToItem
    property bool fullyOpened: false

    anchor.item: moveToItem
    anchor.rect.y: moveToItem.height
    anchor.rect.x: (-implicitWidth / 2) + moveToItem.width / 2
    implicitHeight: 300
    implicitWidth: 50
    visible: false
    color: "transparent"

    onVisibleChanged: {
        if (!visible) {
            fullyOpened = false
            volumeSliderHost.implicitHeight = 1
        }
    }

    Rectangle {
        id: volumeSliderHost
        color: Settings.volumeControllerBackgroundColor
        implicitWidth: root.implicitWidth
        implicitHeight: 1
        radius: 16

        states: State {
            name: "opened"
            when: root.visible
            PropertyChanges {
                target: volumeSliderHost
                implicitHeight: root.implicitHeight
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "implicitHeight"
                duration: 200
                easing.type: Easing.OutBack
            }

            onRunningChanged: {
                if (!running) {
                    root.fullyOpened = root.visible
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Slider {
                id: volumeSlider

                property bool offCooldown: true
                property double currentVolume: AudioControl.currentVolume

                value: { value = currentVolume }

                onCurrentVolumeChanged: {
                    value = currentVolume
                }

                from: -2
                to: Settings.audioProtection ? Settings.audioMaxVolume + 2 : 201
                stepSize: 1
                live: true
                orientation: Qt.Vertical

                implicitWidth: 30
                implicitHeight: 1
                Layout.fillHeight: true
                Layout.topMargin: 15
                Layout.alignment: Qt.AlignHCenter

                background: Rectangle {
                    implicitHeight: 200
                    implicitWidth: volumeSlider.implicitWidth
                    height: volumeSlider.availableHeight
                    width: implicitWidth
                    radius: 7
                    color: Settings.flamingo
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        color: Settings.mantle
                        implicitWidth: parent.implicitWidth
                        implicitHeight: volumeSlider.visualPosition * parent.height
                        onImplicitHeightChanged:{
                        }
                    }
                }

                handle: Rectangle {
                    id: volumeHandle

                    implicitWidth: volumeSlider.implicitWidth
                    implicitHeight: 0
                    radius: 7
                    color: Settings.flamingo
                    border.width: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    x: control.leftPadding + control.visualPosition * (volumeSlider.availableHeight - width)

                    y: (volumeSlider.availableHeight > 0) ?
                        volumeSlider.visualPosition * (volumeSlider.availableHeight - implicitHeight) : 0

                    onYChanged: {
                        if (root.fullyOpened && volumeSlider.offCooldown) {
                            volumeSlider.offCooldown = false
                            AudioControl.sink.audio.volume = volumeSlider.value / 100
                            cooldownTimer.running = true
                        }
                    }
                }

                Timer {
                    id: cooldownTimer
                    interval: 5
                    running: false

                    onTriggered: {
                        volumeSlider.offCooldown = true
                        cooldownTimer.running = false
                    }
                }
            }

            Label {
                text: "󰕾"
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontPixelSize + 2
                color: Settings.flamingo
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
            }
        }
    }
}
