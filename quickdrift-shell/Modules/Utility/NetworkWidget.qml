import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    readonly property var devices: NetworkController.devices
    readonly property var connectedWiredDevices: devices.filter(device =>
        device.type === DeviceType.Wired && device.connected)
    readonly property var connectedWifiDevices: devices.filter(device =>
        device.type === DeviceType.Wifi && device.connected)
    readonly property bool backendAvailable:
        Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool connected: devices.some(device => device.connected)
    readonly property bool connecting: devices.some(device =>
        device.state === ConnectionState.Connecting)
    readonly property real strongestWifiSignal: {
        let strongest = 0

        for (const device of connectedWifiDevices) {
            for (const network of device.networks.values) {
                if (network.connected)
                    strongest = Math.max(strongest, network.signalStrength)
            }
        }

        return strongest
    }
    readonly property string statusIcon: {
        if (!backendAvailable)
            return Settings.networkDisconnectedIcon

        if (connectedWiredDevices.length > 0)
            return Settings.networkWiredIcon

        if (connectedWifiDevices.length > 0)
            return wifiIconForSignal(strongestWifiSignal)

        if (connecting)
            return Settings.networkConnectingIcon

        return Settings.networkDisconnectedIcon
    }
    readonly property string statusText: {
        if (!backendAvailable)
            return "Network backend unavailable"

        if (connectedWiredDevices.length > 0)
            return "Ethernet connected"

        if (connectedWifiDevices.length > 0)
            return "Wi-Fi connected"

        if (connected)
            return "Network connected"

        if (connecting)
            return "Network connecting"

        return "Network disconnected"
    }

    function wifiIconForSignal(signalStrength) {
        const icons = Settings.networkWifiIcons
        if (!icons || icons.length < 4)
            return Settings.networkConnectingIcon

        const percent = Number.isFinite(signalStrength)
            ? Math.max(0, Math.min(100, signalStrength * 100))
            : 0
        if (percent < 25)
            return icons[0]
        if (percent < 50)
            return icons[1]
        if (percent < 75)
            return icons[2]
        return icons[3]
    }

    implicitWidth: Math.max(28, networkText.implicitWidth + 10)
    implicitHeight: Settings.taskbarHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: statusText
    Accessible.description: "Open network information"

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: pointer.containsMouse || networkFlyout.visible
            ? Settings.mantle
            : "transparent"
    }

    StyledText {
        id: networkText
        anchors.centerIn: parent
        text: root.statusIcon
        pixelSize: 16
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: networkFlyout.cancelPointerDismiss()
        onExited: networkFlyout.schedulePointerDismiss()
        onClicked: networkFlyout.toggle()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            networkFlyout.toggle()
            event.accepted = true
        }
    }

    NetworkFlyout {
        id: networkFlyout
        moveToItem: root
    }
}
