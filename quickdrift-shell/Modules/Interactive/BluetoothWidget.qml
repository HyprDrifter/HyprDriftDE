import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    readonly property var connectedDevices: BluetoothController.connectedDevices
    readonly property bool available: BluetoothController.available
    readonly property bool connected: BluetoothController.connected
    readonly property bool scanning: BluetoothController.discovering
    readonly property bool bluetoothEnabled: BluetoothController.hasEnabledAdapter
    readonly property bool transitioning: BluetoothController.transitioning
    readonly property bool blocked: BluetoothController.blocked
    readonly property string statusIcon: {
        if (connected)
            return Settings.bluetoothConnectedIcon;
        if (scanning)
            return Settings.bluetoothScanningIcon;
        if (bluetoothEnabled)
            return Settings.bluetoothEnabledIcon;
        if (transitioning)
            return Settings.bluetoothTransitioningIcon;
        return Settings.bluetoothDisabledIcon;
    }
    readonly property string statusText: {
        if (!available)
            return "Bluetooth unavailable";

        if (connected) {
            const count = connectedDevices.length;
            const connection = count === 1 ? BluetoothController.displayName(connectedDevices[0]) + " connected" : count + " Bluetooth devices connected";
            return scanning ? connection + ", searching" : connection;
        }

        if (scanning)
            return "Bluetooth searching for devices";
        if (bluetoothEnabled)
            return "Bluetooth enabled";
        if (transitioning)
            return "Bluetooth changing power state";
        if (blocked)
            return "Bluetooth blocked";
        return "Bluetooth disabled";
    }

    implicitWidth: Math.max(28, bluetoothText.implicitWidth + 10)
    implicitHeight: Settings.taskbarHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: statusText
    Accessible.description: "Open Bluetooth device manager"

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: pointer.containsMouse || root.activeFocus || bluetoothFlyout.visible ? Settings.mantle : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: scanHalo

        anchors.centerIn: parent
        width: 22
        height: 22
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Settings.blue
        visible: root.scanning && !root.connected
        opacity: 0
        scale: 0.65
    }

    StyledText {
        id: bluetoothText

        anchors.centerIn: parent
        text: root.statusIcon
        pixelSize: 16
        fontColor: root.connected ? Settings.green : root.scanning || root.transitioning ? Settings.blue : Settings.fontColor
    }

    ParallelAnimation {
        id: scanAnimation

        running: root.scanning && !root.connected
        loops: Animation.Infinite

        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: bluetoothText
                    property: "scale"
                    from: 0.88
                    to: 1.12
                    duration: 540
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: bluetoothText
                    property: "opacity"
                    from: 0.72
                    to: 1
                    duration: 540
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: bluetoothText
                    property: "scale"
                    from: 1.12
                    to: 0.88
                    duration: 540
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: bluetoothText
                    property: "opacity"
                    from: 1
                    to: 0.72
                    duration: 540
                }
            }
        }

        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: scanHalo
                    property: "scale"
                    from: 0.65
                    to: 1.3
                    duration: 760
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: scanHalo
                    property: "opacity"
                    from: 0.65
                    to: 0
                    duration: 760
                    easing.type: Easing.OutQuad
                }
            }

            PauseAnimation {
                duration: 320
            }
        }

        onRunningChanged: {
            if (!running) {
                bluetoothText.scale = 1;
                bluetoothText.opacity = 1;
                scanHalo.scale = 0.65;
                scanHalo.opacity = 0;
            }
        }
    }

    RotationAnimator {
        id: transitionAnimation

        target: bluetoothText
        running: root.transitioning && !root.connected && !root.scanning
        from: 0
        to: 360
        duration: 1100
        loops: Animation.Infinite

        onRunningChanged: {
            if (!running)
                bluetoothText.rotation = 0;
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: bluetoothFlyout.cancelPointerDismiss()
        onExited: bluetoothFlyout.schedulePointerDismiss()
        onClicked: bluetoothFlyout.toggle()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            bluetoothFlyout.toggle();
            event.accepted = true;
        }
    }

    BluetoothFlyout {
        id: bluetoothFlyout

        moveToItem: root
    }
}
