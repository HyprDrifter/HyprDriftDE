pragma ComponentBehavior: Bound
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls as Controls
import qs.Modules.Driftlets
import qs.Modules.Services

Rectangle {
    id: root

    required property var orientation
    required property string controlledAppName
    property bool vertical: orientation == Qt.Vertical
    property bool horizontal: orientation == Qt.Horizontal
    property QtObject delegateBool: QtObject {
        property bool vertical: root.vertical
    }
    property VolumeNode node
    property int volume: 0

    Layout.fillHeight: vertical
    Layout.fillWidth: horizontal
    Layout.preferredHeight: Layout.fillHeight ? 300 : 75
    Layout.preferredWidth: Layout.fillWidth ? 400 : 80
    color: "transparent"


    border {
        color: ThemeSettings.taskbarTrayBorderColor
        width: 1
    }


    Instantiator {
        id: layoutInstantiator

        model: root.delegateBool
        delegate: DelegateChooser {
            role: "vertical"

            DelegateChoice {
                roleValue: "true"
                delegate: Component {
                    ColumnLayout {
                        anchors.fill: parent
                        TextComponent {}
                        VolSlider {}
                        VolumeComponent{}
                    }
                }
            }

            DelegateChoice {
                roleValue: "false"
                delegate: Component {
                    RowLayout {
                        anchors.fill: parent
                        TextComponent {}
                        VolSlider {}
                        VolumeComponent{}
                    }
                }
            }
        }
        onObjectAdded: (index, object) => {
            object.parent = root;
        }
    }

    component TextComponent: Text {
        text: root.controlledAppName
        color: ThemeSettings.fontColor

        property bool vertical: root.vertical
        property bool horizontal: root.horizontal
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: vertical ? 10 : 5
        Layout.bottomMargin: vertical ? 10 : 5
        Layout.leftMargin: horizontal ? 10 : 5
        Layout.rightMargin: horizontal ? 10 : 5
    }

    component VolumeComponent: Text {
        text: `${root.volume ?? 0}%`
        color: ThemeSettings.fontColor

        property bool vertical: root.vertical
        property bool horizontal: root.horizontal
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: vertical ? 10 : 5
        Layout.bottomMargin: vertical ? 10 : 5
        Layout.leftMargin: horizontal ? 10 : 5
        Layout.rightMargin: horizontal ? 10 : 5
    }

    component VolSlider: Controls.Sliders.DefaultSlider {
        id: slider

        min: 0
        max: VolumeBroker.maxVolume
        value: root.node && root.node.isReady ? root.node.volumePercent : 0
        stepSize: Settings.system.volumeSettings.volumeStep
        orientation: root.orientation
        snapMode:Slider.SnapAlways
        Layout.topMargin: vertical ? 10 : 5
        Layout.bottomMargin: vertical ? 10 : 5
        Layout.leftMargin: horizontal ? 10 : 5
        Layout.rightMargin: horizontal ? 10 : 5
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: true
        Layout.fillWidth: true

        Behavior on implicitWidth {
            NumberAnimation {
                duration: slider.implicitWidth / 1.5
                easing.type: Easing.OutQuint
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: slider.implicitHeight / 1.5
                easing.type: Easing.OutQuint
            }
        }

        Connections {
            target: root.node
            function onReady() {
                slider.value = root.node.volumePercent;
                root.volume = slider.value;
            }
            function onVolumeChanged(newVolume) {
                if (!pressed) {
                    slider.value = newVolume;
                }
                root.volume = pressed ? slider.value : newVolume;
            }
        }

        Component.onCompleted: {
            if (root.node && root.node.isReady) {
                slider.value = root.node.volumePercent;
                root.volume = slider.value;
            }
        }

        onPressedChanged: {
            if (!root.node)
                return;

            root.node.controllerChanging = pressed;

            if (!pressed) {
                root.node.syncFromNode(true);
            }
        }

        onValueChanged: {
            if (pressed && root.node) {
                root.node.setVolume(slider.value);
                root.volume = slider.value;
            }
        }

    }
}
