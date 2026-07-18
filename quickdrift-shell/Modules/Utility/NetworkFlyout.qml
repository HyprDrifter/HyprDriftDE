pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

PopupWindow {
    id: root

    required property Item moveToItem

    property bool closing: false
    property real flyoutOpacity: 0
    property real flyoutScale: 0.9
    property real flyoutOffset: -18
    property real contentOpacity: 0
    property real contentOffset: 8
    property real accentProgress: 0
    property bool pointerHasEntered: false
    property bool geometryAnimationsEnabled: false
    property int scanOwnerToken: 0
    property bool scanProgressActive: false
    property var passwordNetwork: null
    property var pskAttemptNetwork: null
    property var confirmForgetNetwork: null
    property string wiredError: ""
    property string wifiError: ""

    readonly property int anchorGap: 8
    readonly property bool verticalAnchor: moveToItem.parent
        ? moveToItem.parent.height > moveToItem.parent.width
        : false

    readonly property var devices: NetworkController.devices
    readonly property var wiredDevices: devices.filter(device =>
        device.type === DeviceType.Wired)
    readonly property var wifiDevices: devices.filter(device =>
        device.type === DeviceType.Wifi)
    readonly property var wifiNetworks: {
        const networks = []

        for (const device of wifiDevices) {
            for (const network of device.networks.values)
                networks.push(network)
        }

        return networks.sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1
            if (left.stateChanging !== right.stateChanging)
                return left.stateChanging ? -1 : 1
            if (left.known !== right.known)
                return left.known ? -1 : 1
            if (left.signalStrength !== right.signalStrength)
                return right.signalStrength - left.signalStrength
            return root.networkName(left).localeCompare(root.networkName(right))
        })
    }
    readonly property var availableWifiNetworks: {
        const networks = wifiNetworks.filter(network => !network.connected)

        return networks.sort((left, right) => {
            if (left.known !== right.known)
                return left.known ? -1 : 1
            if (left.stateChanging !== right.stateChanging)
                return left.stateChanging ? -1 : 1
            if (left.signalStrength !== right.signalStrength)
                return right.signalStrength - left.signalStrength
            return root.networkName(left).localeCompare(root.networkName(right))
        })
    }
    readonly property var connectedWifiNetworks: wifiNetworks.filter(network =>
        network.connected)
    readonly property bool wifiScanning: wifiDevices.some(device =>
        device.scannerEnabled)
    readonly property bool ownsWifiScan:
        NetworkController.ownsScan(scanOwnerToken)
    readonly property bool searchInProgress: scanProgressActive
    readonly property bool canScanWifi: backendAvailable
        && wifiDevices.length > 0
        && Networking.wifiHardwareEnabled
        && Networking.wifiEnabled
    readonly property bool wifiBusy: wifiNetworks.some(network =>
        network.stateChanging)
    readonly property bool backendAvailable:
        Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool connected: devices.some(device => device.connected)
    readonly property bool connecting: devices.some(device =>
        device.state === ConnectionState.Connecting)
    readonly property string overallStatus: {
        if (!backendAvailable)
            return "Backend unavailable"
        if (connected)
            return "Connected"
        if (connecting)
            return "Connecting"
        return "Disconnected"
    }
    readonly property color overallStatusColor: {
        if (!backendAvailable)
            return Settings.red
        if (connected)
            return Settings.green
        if (connecting)
            return Settings.yellow
        return Settings.red
    }

    function connectionStateText(state) {
        switch (state) {
        case ConnectionState.Connecting:
            return "Connecting"
        case ConnectionState.Connected:
            return "Connected"
        case ConnectionState.Disconnecting:
            return "Disconnecting"
        case ConnectionState.Disconnected:
            return "Disconnected"
        default:
            return "Unknown"
        }
    }

    function networkName(network) {
        if (!network)
            return "Unknown network"

        const name = String(network.name || "").trim()
        return name.length > 0 ? name : "Hidden network"
    }

    function wifiSignalPercent(network) {
        if (!network || !Number.isFinite(network.signalStrength))
            return 0
        return Math.round(Math.max(0, Math.min(1, network.signalStrength)) * 100)
    }

    function wifiIconForSignal(network) {
        const icons = Settings.networkWifiIcons
        if (!icons || icons.length < 4)
            return Settings.networkConnectingIcon

        const percent = wifiSignalPercent(network)
        if (percent < 25)
            return icons[0]
        if (percent < 50)
            return icons[1]
        if (percent < 75)
            return icons[2]
        return icons[3]
    }

    function wifiSecurityText(security) {
        switch (security) {
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3 Enterprise"
        case WifiSecurityType.Sae:
            return "WPA3 Personal"
        case WifiSecurityType.Wpa2Eap:
            return "WPA2 Enterprise"
        case WifiSecurityType.Wpa2Psk:
            return "WPA2 Personal"
        case WifiSecurityType.WpaEap:
            return "WPA Enterprise"
        case WifiSecurityType.WpaPsk:
            return "WPA Personal"
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP"
        case WifiSecurityType.Leap:
            return "LEAP"
        case WifiSecurityType.Owe:
            return "Enhanced Open"
        case WifiSecurityType.Open:
            return "Open"
        default:
            return "Security unknown"
        }
    }

    function supportsPsk(network) {
        return network && (network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae)
    }

    function isOpenNetwork(network) {
        return network && (network.security === WifiSecurityType.Open
            || network.security === WifiSecurityType.Owe)
    }

    function passwordValid(network, password) {
        if (!network)
            return false

        const length = password.length
        if (network.security === WifiSecurityType.Sae)
            return length > 0 && length <= 63

        return (length >= 8 && length <= 63)
            || (length === 64 && /^[0-9a-fA-F]+$/.test(password))
    }

    function clearPasswordPrompt() {
        passwordNetwork = null
    }

    function clearForgetConfirmation() {
        confirmForgetNetwork = null
    }

    function promptForPassword(network) {
        wifiError = ""
        clearForgetConfirmation()
        passwordNetwork = network
    }

    function beginForgetNetwork(network) {
        if (!network || !network.known || network.stateChanging || wifiBusy)
            return

        wifiError = ""
        clearPasswordPrompt()
        confirmForgetNetwork = network
    }

    function forgetSavedNetwork(network) {
        if (!network || !network.known || network.stateChanging || wifiBusy) {
            clearForgetConfirmation()
            return
        }

        const name = networkName(network)
        wifiError = ""
        if (pskAttemptNetwork === network)
            pskAttemptNetwork = null
        clearPasswordPrompt()
        clearForgetConfirmation()

        try {
            network.forget()
        } catch (error) {
            console.warn("Wi-Fi forget request failed:", error)
            wifiError = "Could not forget " + name + "."
        }
    }

    function connectionFailureText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "A password or saved credential is required."
        case ConnectionFailReason.WifiClientDisconnected:
            return "The Wi-Fi device disconnected before joining the network."
        case ConnectionFailReason.WifiClientFailed:
            return "The Wi-Fi device could not complete the connection."
        case ConnectionFailReason.WifiAuthTimeout:
            return "Wi-Fi authentication timed out."
        case ConnectionFailReason.WifiNetworkLost:
            return "The network disappeared while connecting."
        default:
            return "Could not connect to the Wi-Fi network."
        }
    }

    function requestWiredConnection(device, enable) {
        if (!device || device.state === ConnectionState.Connecting
                || device.state === ConnectionState.Disconnecting)
            return

        wiredError = ""

        try {
            if (enable) {
                if (!device.network) {
                    wiredError = "No wired connection profile is available."
                    return
                }
                device.network.connect()
            } else {
                device.disconnect()
            }
        } catch (error) {
            console.warn("Ethernet connection request failed:", error)
            wiredError = enable
                ? "Could not enable the wired connection."
                : "Could not disconnect the wired connection."
        }
    }

    function handleConnectionFailure(network, reason) {
        const passwordWasSubmitted = pskAttemptNetwork === network
        pskAttemptNetwork = null

        if (reason === ConnectionFailReason.NoSecrets && supportsPsk(network)) {
            promptForPassword(network)
            if (passwordWasSubmitted)
                wifiError = "The password was rejected. Check it and try again."
            return
        }

        wifiError = connectionFailureText(reason)
    }

    function requestNetworkConnection(network) {
        if (!network || network.stateChanging || wifiBusy)
            return

        wifiError = ""
        pskAttemptNetwork = null
        clearPasswordPrompt()
        clearForgetConfirmation()

        if (network.connected) {
            network.disconnect()
            return
        }

        if (network.known || isOpenNetwork(network)
                || network.security === WifiSecurityType.Unknown) {
            network.connect()
            return
        }

        if (supportsPsk(network)) {
            promptForPassword(network)
            return
        }

        wifiError = networkName(network)
            + " requires enterprise or legacy credentials. Use system network settings to connect."
    }

    function submitNetworkPassword(network, password) {
        if (!network || !passwordValid(network, password))
            return

        wifiError = ""
        pskAttemptNetwork = network
        clearPasswordPrompt()
        network.connectWithPsk(password)
    }

    function ensureAvailableNetworkVisible(item) {
        if (!item || !availableNetworkScroll.visible)
            return

        const position = item.mapToItem(availableNetworkList, 0, 0)
        const margin = 6
        const top = Math.max(0, position.y - margin)
        const bottom = position.y + item.height + margin

        if (top < availableNetworkScroll.contentY) {
            availableNetworkScroll.contentY = top
        } else if (bottom > availableNetworkScroll.contentY
                + availableNetworkScroll.height) {
            availableNetworkScroll.contentY = Math.min(
                Math.max(0, availableNetworkScroll.contentHeight
                    - availableNetworkScroll.height),
                bottom - availableNetworkScroll.height)
        }
    }

    function startWifiScan() {
        wifiError = ""

        if (!canScanWifi) {
            wifiError = Networking.wifiHardwareEnabled
                ? "Enable Wi-Fi before searching for networks."
                : "Wi-Fi is blocked by a hardware switch."
            return
        }

        NetworkController.acquireScan(scanOwnerToken)
        scanProgressActive = true
        wifiScanTimer.restart()

        if (!wifiScanning)
            wifiError = "Could not start Wi-Fi scanning."
    }

    function setWifiEnabled(enabled) {
        if (!backendAvailable || !Networking.wifiHardwareEnabled
                || Networking.wifiEnabled === enabled)
            return

        wifiError = ""
        if (!enabled)
            stopWifiScan()

        try {
            Networking.wifiEnabled = enabled
        } catch (error) {
            console.warn("Wi-Fi power request failed:", error)
            wifiError = enabled
                ? "Could not turn Wi-Fi on."
                : "Could not turn Wi-Fi off."
        }
    }

    function stopWifiScan() {
        wifiScanTimer.stop()
        scanProgressActive = false
        NetworkController.releaseScan(scanOwnerToken)
    }

    function resetAnimationState() {
        flyoutOpacity = 0
        flyoutScale = 0.9
        flyoutOffset = -18
        contentOpacity = 0
        contentOffset = 8
        accentProgress = 0
    }

    function reveal() {
        hoverDismissTimer.stop()

        if (visible) {
            if (closing) {
                closeAnimation.stop()
                closing = false
                geometryAnimationsEnabled = false
                openAnimation.restart()
                Qt.callLater(() => card.forceActiveFocus())
            }
            return
        }

        visible = true
    }

    function dismiss() {
        if (!visible || closing)
            return

        hoverDismissTimer.stop()
        stopWifiScan()
        openAnimation.stop()
        closing = true
        geometryAnimationsEnabled = false
        focusGrab.active = false
        closeAnimation.restart()
    }

    function cancelPointerDismiss() {
        pointerHasEntered = true
        hoverDismissTimer.stop()
    }

    function schedulePointerDismiss() {
        if (visible && !closing && pointerHasEntered)
            hoverDismissTimer.restart()
    }

    function activateTextInput(input) {
        if (!input)
            return

        focusGrab.active = true
        Qt.callLater(() => {
            if (!root.visible || root.closing)
                return
            input.forceActiveFocus()
        })
    }

    function toggle() {
        if (visible)
            dismiss()
        else
            reveal()
    }

    visible: false
    grabFocus: false
    color: "transparent"
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 24

    Behavior on implicitWidth {
        enabled: root.geometryAnimationsEnabled

        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        enabled: root.geometryAnimationsEnabled

        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    anchor.item: moveToItem
    anchor.edges: verticalAnchor ? Edges.Right : Edges.Bottom
    anchor.gravity: verticalAnchor ? Edges.Right : Edges.Bottom
    anchor.margins.left: verticalAnchor ? -anchorGap : 0
    anchor.margins.right: verticalAnchor ? -anchorGap : 0
    anchor.margins.top: verticalAnchor ? 0 : -anchorGap
    anchor.margins.bottom: verticalAnchor ? 0 : -anchorGap
    anchor.adjustment: PopupAdjustment.All

    onVisibleChanged: {
        if (visible) {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            closing = false
            geometryAnimationsEnabled = false
            resetAnimationState()
            openAnimation.restart()
            Qt.callLater(() => {
                focusGrab.active = true
                card.forceActiveFocus()
                if (canScanWifi)
                    startWifiScan()
            })
        } else {
            hoverDismissTimer.stop()
            pointerHasEntered = false
            stopWifiScan()
            clearPasswordPrompt()
            clearForgetConfirmation()
            pskAttemptNetwork = null
            wiredError = ""
            wifiError = ""
            openAnimation.stop()
            closeAnimation.stop()
            focusGrab.active = false
            closing = false
            geometryAnimationsEnabled = false
            resetAnimationState()
        }
    }

    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]

        onCleared: {
            if (root.visible && !root.closing)
                root.dismiss()
        }
    }

    Timer {
        id: hoverDismissTimer

        interval: 180
        repeat: false
        onTriggered: root.dismiss()
    }

    Timer {
        id: wifiScanTimer

        interval: 5000
        repeat: false
        onTriggered: root.stopWifiScan()
    }

    Connections {
        target: Networking

        function onWifiEnabledChanged(): void {
            if (!Networking.wifiEnabled) {
                root.stopWifiScan()
            } else if (root.visible && !root.closing) {
                Qt.callLater(() => root.startWifiScan())
            }
        }
    }

    onWifiScanningChanged: {
        if (visible && !closing && canScanWifi && searchInProgress
                && !wifiScanning)
            Qt.callLater(() => NetworkController.acquireScan(scanOwnerToken))
    }

    onWifiDevicesChanged: {
        if (visible && !closing && canScanWifi && searchInProgress)
            Qt.callLater(() => NetworkController.acquireScan(scanOwnerToken))
    }

    onWifiNetworksChanged: {
        if (passwordNetwork && wifiNetworks.indexOf(passwordNetwork) < 0)
            clearPasswordPrompt()
        if (confirmForgetNetwork
                && (wifiNetworks.indexOf(confirmForgetNetwork) < 0
                    || !confirmForgetNetwork.known))
            clearForgetConfirmation()
    }

    Component.onCompleted: scanOwnerToken = NetworkController.createScanOwner()
    Component.onDestruction: NetworkController.releaseScan(scanOwnerToken)

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: root
            property: "flyoutOpacity"
            to: 1
            duration: 150
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: root
            property: "flyoutScale"
            to: 1
            duration: 360
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }

        NumberAnimation {
            target: root
            property: "flyoutOffset"
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 55
            }

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "contentOpacity"
                    to: 1
                    duration: 190
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: root
                    property: "contentOffset"
                    to: 0
                    duration: 230
                    easing.type: Easing.OutCubic
                }
            }
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 95
            }

            NumberAnimation {
                target: root
                property: "accentProgress"
                to: 1
                duration: 280
                easing.type: Easing.OutExpo
            }
        }

        onFinished: {
            if (root.visible && !root.closing)
                root.geometryAnimationsEnabled = true
        }
    }

    ParallelAnimation {
        id: closeAnimation

        NumberAnimation {
            target: root
            property: "contentOpacity"
            to: 0
            duration: 90
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "contentOffset"
            to: 5
            duration: 130
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "accentProgress"
            to: 0
            duration: 110
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "flyoutOpacity"
            to: 0
            duration: 170
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "flyoutScale"
            to: 0.96
            duration: 170
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "flyoutOffset"
            to: -10
            duration: 170
            easing.type: Easing.InCubic
        }

        onFinished: {
            root.visible = false
        }
    }

    component ActionButton: Button {
        id: control

        property color accentColor: Settings.blue
        property bool destructive: false
        property bool iconOnly: false
        property bool spinning: false
        property bool compact: false
        property string accessibleName: text

        activeFocusOnTab: enabled
        implicitHeight: compact ? 24 : 30
        implicitWidth: iconOnly
            ? implicitHeight
            : Math.max(compact ? 58 : 68,
                buttonLabel.implicitWidth + (compact ? 12 : 18))

        Accessible.name: accessibleName

        contentItem: Text {
            id: buttonLabel

            text: control.text
            color: control.enabled
                ? control.destructive ? Settings.red : Settings.text
                : Settings.rosewater
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontPixelSize - 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        RotationAnimator {
            target: buttonLabel
            running: control.spinning && control.visible
            from: 0
            to: 360
            duration: 800
            loops: Animation.Infinite

            onRunningChanged: {
                if (!running)
                    buttonLabel.rotation = 0
            }
        }

        background: Rectangle {
            radius: 7
            color: {
                if (!control.enabled)
                    return Settings.surface0
                if (control.down)
                    return Settings.mantle
                if (control.hovered || control.visualFocus)
                    return Settings.surface1
                return Settings.surface0
            }
            border.width: control.visualFocus || control.hovered ? 1 : 0
            border.color: control.destructive ? Settings.red : control.accentColor
            opacity: control.enabled ? 1 : 0.55

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }
    }

    component WifiNetworkRow: Rectangle {
        id: networkRow

        required property var network
        property bool scrollIntoView: false
        property bool passwordValidationRequested: false

        readonly property bool prompting: root.passwordNetwork === network
        readonly property bool confirmingForget:
            root.confirmForgetNetwork === network
        readonly property bool passwordIsValid:
            root.passwordValid(network, passwordField.text)
        readonly property bool showPasswordError: prompting
            && !passwordIsValid
            && (passwordValidationRequested || passwordField.text.length > 0)
        readonly property int signalPercent: root.wifiSignalPercent(network)
        readonly property string interfaceName: network && network.device
            && String(network.device.name || "").trim().length > 0
            ? network.device.name
            : "Unknown interface"
        readonly property string actionText: {
            if (network.state === ConnectionState.Connecting)
                return "Connecting…"
            if (network.state === ConnectionState.Disconnecting)
                return "Disconnecting…"
            return network.connected ? "Disconnect" : "Connect"
        }
        readonly property string connectionStatusIcon: {
            if (network.stateChanging)
                return Settings.networkConnectingIcon
            return network.connected ? Settings.networkConnectedStatusIcon : ""
        }
        readonly property color connectionStatusColor: {
            if (network.stateChanging)
                return Settings.yellow
            return network.connected ? Settings.green : Settings.rosewater
        }

        Layout.fillWidth: true
        implicitHeight: networkContent.implicitHeight + 10
        radius: 7
        color: Settings.surface0
        border.width: network.connected || network.stateChanging || prompting
            || confirmingForget ? 1 : 0
        border.color: network.connected
            ? Settings.green
            : confirmingForget ? Settings.red
            : prompting ? Settings.blue : Settings.yellow

        Behavior on y {
            enabled: root.geometryAnimationsEnabled

            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        onPromptingChanged: {
            if (prompting) {
                passwordValidationRequested = false
                root.activateTextInput(passwordField)
                if (networkRow.scrollIntoView)
                    Qt.callLater(() => root.ensureAvailableNetworkVisible(networkRow))
            } else {
                passwordValidationRequested = false
                passwordField.clear()
            }
        }

        Connections {
            target: networkRow.network

            function onConnectionFailed(reason): void {
                root.handleConnectionFailure(networkRow.network, reason)
            }

            function onStateChanged(): void {
                if (!networkRow.network.connected)
                    return

                if (root.pskAttemptNetwork === networkRow.network)
                    root.pskAttemptNetwork = null
                root.wifiError = ""
            }
        }

        ColumnLayout {
            id: networkContent

            anchors.fill: parent
            anchors.margins: 5
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    text: root.wifiIconForSignal(networkRow.network)
                    fontColor: networkRow.network.connected
                        ? Settings.green
                        : Settings.text
                    pixelSize: 16
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        StyledText {
                            Layout.fillWidth: true
                            text: root.networkName(networkRow.network)
                            fontColor: Settings.text
                            bold: true
                            txt.width: width
                            txt.elide: Text.ElideRight
                            txt.maximumLineCount: 1
                        }

                        ActionButton {
                            visible: networkRow.network.known
                                && !networkRow.prompting
                                && !networkRow.confirmingForget
                            text: "Forget"
                            compact: true
                            destructive: true
                            enabled: !root.wifiBusy
                                && !networkRow.network.stateChanging

                            onClicked: root.beginForgetNetwork(networkRow.network)
                        }

                        ActionButton {
                            visible: !networkRow.prompting
                                && !networkRow.confirmingForget
                            text: networkRow.actionText
                            compact: true
                            enabled: !root.wifiBusy
                                && !networkRow.network.stateChanging
                            destructive: networkRow.network.connected

                            onClicked: root.requestNetworkConnection(
                                networkRow.network)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            text: root.wifiSecurityText(networkRow.network.security)
                                + (root.wifiDevices.length > 1
                                    ? " · " + networkRow.interfaceName : "")
                            fontColor: Settings.rosewater
                            pixelSize: Settings.fontPixelSize - 2
                            txt.width: width
                            txt.elide: Text.ElideRight
                            txt.maximumLineCount: 1
                        }

                        StyledText {
                            text: networkRow.signalPercent + "%"
                            fontColor: networkRow.signalPercent >= 50
                                ? Settings.green : Settings.rosewater
                            pixelSize: Settings.fontPixelSize - 2
                        }

                        StyledText {
                            visible: networkRow.connectionStatusIcon.length > 0
                            text: networkRow.connectionStatusIcon
                            fontColor: networkRow.connectionStatusColor
                            pixelSize: Settings.fontPixelSize - 2
                            Accessible.name: root.connectionStateText(
                                networkRow.network.state)
                        }

                        StyledText {
                            visible: networkRow.network.known
                            text: Settings.networkSavedIcon
                            fontColor: Settings.blue
                            pixelSize: Settings.fontPixelSize - 2
                            Accessible.name: "Saved network"
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: networkRow.prompting && !networkRow.confirmingForget
                text: "Enter the password for " + root.networkName(networkRow.network)
                fontColor: Settings.rosewater
                pixelSize: Settings.fontPixelSize - 1
                txt.width: width
                txt.wrapMode: Text.WordWrap
            }

            TextField {
                id: passwordField

                Layout.fillWidth: true
                visible: networkRow.prompting && !networkRow.confirmingForget
                activeFocusOnTab: visible
                placeholderText: "Wi-Fi password"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                selectByMouse: true
                color: Settings.text
                placeholderTextColor: Settings.rosewater
                font.family: Settings.fontFamily
                font.pixelSize: Settings.fontPixelSize

                background: Rectangle {
                    radius: 7
                    color: Settings.mantle
                    border.width: passwordField.activeFocus
                        || networkRow.showPasswordError ? 1 : 0
                    border.color: networkRow.showPasswordError
                        ? Settings.red : Settings.blue
                }

                onAccepted: {
                    if (!networkRow.passwordIsValid) {
                        networkRow.passwordValidationRequested = true
                        root.activateTextInput(passwordField)
                        return
                    }

                    const password = text
                    clear()
                    root.submitNetworkPassword(networkRow.network, password)
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: networkRow.showPasswordError
                text: passwordField.text.length === 0
                    ? "Enter a Wi-Fi password."
                    : networkRow.network.security === WifiSecurityType.Sae
                    ? "Enter a password up to 63 characters."
                    : "Use 8–63 characters, or a 64-digit hexadecimal key."
                fontColor: Settings.red
                pixelSize: Settings.fontPixelSize - 2
                txt.width: width
                txt.wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                visible: networkRow.prompting && !networkRow.confirmingForget
                spacing: 5

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    text: "Cancel"
                    compact: true
                    onClicked: root.clearPasswordPrompt()
                }

                ActionButton {
                    visible: networkRow.network.known
                    text: "Forget"
                    compact: true
                    destructive: true
                    enabled: !root.wifiBusy && !networkRow.network.stateChanging

                    onClicked: root.beginForgetNetwork(networkRow.network)
                }

                ActionButton {
                    text: "Connect"
                    compact: true
                    enabled: !root.wifiBusy && !networkRow.network.stateChanging

                    onClicked: {
                        if (!networkRow.passwordIsValid) {
                            networkRow.passwordValidationRequested = true
                            root.activateTextInput(passwordField)
                            return
                        }

                        const password = passwordField.text
                        passwordField.clear()
                        root.submitNetworkPassword(networkRow.network, password)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: networkRow.confirmingForget
                spacing: 5

                StyledText {
                    Layout.fillWidth: true
                    text: "Forget saved network?"
                    fontColor: Settings.red
                    pixelSize: Settings.fontPixelSize - 1
                }

                ActionButton {
                    text: "Keep"
                    compact: true
                    onClicked: root.clearForgetConfirmation()
                }

                ActionButton {
                    text: "Forget"
                    compact: true
                    destructive: true
                    enabled: !root.wifiBusy && !networkRow.network.stateChanging

                    onClicked: root.forgetSavedNetwork(networkRow.network)
                }
            }
        }
    }

    Rectangle {
        id: card

        anchors.fill: parent
        enabled: root.visible && !root.closing
        focus: true
        clip: true
        opacity: root.flyoutOpacity
        scale: root.flyoutScale
        transformOrigin: Item.TopRight
        radius: 12
        color: Settings.background
        border.width: 1
        border.color: Settings.surface1

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.cancelPointerDismiss()
                else
                    root.schedulePointerDismiss()
            }
        }

        transform: Translate {
            y: root.flyoutOffset
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss()
                event.accepted = true
            }
        }

        Rectangle {
            id: accentLine

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, (parent.width - 28) * root.accentProgress)
            height: 2
            radius: 1
            color: root.overallStatusColor
            opacity: 0.9 * root.flyoutOpacity
        }

        ColumnLayout {
            id: content

            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.contentOffset
            spacing: 10
            opacity: root.contentOpacity

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Network"
                    pixelSize: Settings.fontLargePixelsize
                    fontColor: Settings.text
                    bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.overallStatus
                    fontColor: root.overallStatusColor
                }
            }

            StyledText {
                visible: !root.backendAvailable
                text: "NetworkManager is unavailable"
                fontColor: Settings.rosewater
            }

            StyledText {
                text: "Ethernet"
                fontColor: Settings.text
                bold: true
            }

            StyledText {
                visible: root.backendAvailable && root.wiredDevices.length === 0
                text: "No Ethernet device detected"
                fontColor: Settings.rosewater
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.wiredError.length > 0
                implicitHeight: wiredErrorText.implicitHeight + 16
                radius: 8
                color: Settings.surface0
                border.width: 1
                border.color: Settings.red

                StyledText {
                    id: wiredErrorText

                    width: parent.width - 16
                    anchors.centerIn: parent
                    text: root.wiredError
                    fontColor: Settings.red
                    pixelSize: Settings.fontPixelSize - 1
                    txt.width: width
                    txt.wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.backendAvailable && root.wiredDevices.length > 0
                spacing: 4

                Repeater {
                    model: ScriptModel {
                        values: root.backendAvailable ? root.wiredDevices : []
                    }

                    delegate: Rectangle {
                        id: wiredEntry

                        required property var modelData
                        readonly property var network: modelData.network
                        readonly property string connectionName: {
                            if (!network)
                                return "Wired connection"
                            const name = String(network.name || "").trim()
                            return name.length > 0 ? name : "Wired connection"
                        }
                        readonly property string interfaceName: {
                            const name = String(modelData.name || "").trim()
                            return name.length > 0 ? name : "Unknown interface"
                        }
                        readonly property string detailText: {
                            let detail = interfaceName
                            if (modelData.linkSpeed > 0)
                                detail += " · " + modelData.linkSpeed + " Mbps"
                            else if (!modelData.hasLink)
                                detail += " · No link"
                            return detail
                        }
                        readonly property bool stateChanging:
                            modelData.state === ConnectionState.Connecting
                                || modelData.state === ConnectionState.Disconnecting
                        readonly property string actionText: {
                            if (modelData.state === ConnectionState.Connecting)
                                return "Enabling…"
                            if (modelData.state === ConnectionState.Disconnecting)
                                return "Disconnecting…"
                            return modelData.connected ? "Disconnect" : "Enable"
                        }

                        Connections {
                            target: wiredEntry.network

                            function onConnectionFailed(): void {
                                root.wiredError = "Could not enable the wired connection."
                            }

                            function onStateChanged(): void {
                                if (wiredEntry.network
                                        && wiredEntry.network.connected)
                                    root.wiredError = ""
                            }
                        }

                        Layout.fillWidth: true
                        implicitHeight: wiredDetails.implicitHeight + 10
                        radius: 7
                        color: Settings.surface0
                        border.width: modelData.connected
                            || wiredEntry.stateChanging ? 1 : 0
                        border.color: modelData.connected
                            ? Settings.green : Settings.yellow

                        Behavior on y {
                            enabled: root.geometryAnimationsEnabled

                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            id: wiredDetails

                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 6

                            StyledText {
                                text: Settings.networkWiredIcon
                                fontColor: wiredEntry.modelData.connected
                                    ? Settings.green : Settings.text
                                pixelSize: 16
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                StyledText {
                                    Layout.fillWidth: true
                                    text: wiredEntry.connectionName
                                    fontColor: Settings.text
                                    bold: true
                                    txt.width: width
                                    txt.elide: Text.ElideRight
                                    txt.maximumLineCount: 1
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: wiredEntry.detailText
                                    fontColor: Settings.rosewater
                                    pixelSize: Settings.fontPixelSize - 2
                                    txt.width: width
                                    txt.elide: Text.ElideRight
                                    txt.maximumLineCount: 1
                                }
                            }

                            ActionButton {
                                text: wiredEntry.actionText
                                compact: true
                                enabled: !wiredEntry.stateChanging
                                    && (wiredEntry.modelData.connected
                                        || wiredEntry.network)
                                destructive: wiredEntry.modelData.connected

                                onClicked: root.requestWiredConnection(
                                    wiredEntry.modelData,
                                    !wiredEntry.modelData.connected)
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Settings.surface1
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                StyledText {
                    text: "Wi-Fi"
                    fontColor: Settings.text
                    bold: true
                }

                StyledText {
                    visible: root.canScanWifi
                        && root.connectedWifiNetworks.length === 0
                    text: "Disconnected"
                    fontColor: Settings.rosewater
                    pixelSize: Settings.fontPixelSize - 1
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    visible: root.backendAvailable
                        && root.wifiDevices.length > 0
                        && Networking.wifiHardwareEnabled
                    text: Settings.networkPowerIcon
                    accessibleName: Networking.wifiEnabled
                        ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
                    iconOnly: true
                    destructive: Networking.wifiEnabled

                    onClicked: root.setWifiEnabled(!Networking.wifiEnabled)
                }

                ActionButton {
                    visible: root.backendAvailable
                        && root.wifiDevices.length > 0
                        && Networking.wifiHardwareEnabled
                        && Networking.wifiEnabled
                    text: root.searchInProgress
                        ? Settings.networkProgressIcon
                        : Settings.networkRefreshIcon
                    accessibleName: root.searchInProgress
                        ? "Searching for Wi-Fi networks"
                        : "Refresh Wi-Fi networks"
                    iconOnly: true
                    spinning: root.searchInProgress
                    enabled: root.canScanWifi && !root.searchInProgress

                    onClicked: root.startWifiScan()
                }
            }

            StyledText {
                visible: root.backendAvailable && root.wifiDevices.length === 0
                text: "No Wi-Fi device detected"
                fontColor: Settings.rosewater
            }

            StyledText {
                visible: root.backendAvailable
                    && root.wifiDevices.length > 0
                    && !Networking.wifiHardwareEnabled
                text: "Wi-Fi is blocked by a hardware switch"
                fontColor: Settings.red
            }

            StyledText {
                visible: root.backendAvailable
                    && root.wifiDevices.length > 0
                    && Networking.wifiHardwareEnabled
                    && !Networking.wifiEnabled
                text: "Wi-Fi radio is turned off"
                fontColor: Settings.rosewater
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.backendAvailable
                    && root.connectedWifiNetworks.length > 0
                spacing: 4

                Repeater {
                    model: ScriptModel {
                        values: root.backendAvailable
                            ? root.connectedWifiNetworks
                            : []
                    }

                    delegate: WifiNetworkRow {
                        required property var modelData

                        network: modelData
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.canScanWifi

                StyledText {
                    text: "Available networks"
                    fontColor: Settings.text
                    bold: true
                    pixelSize: Settings.fontPixelSize - 1
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    visible: root.availableWifiNetworks.length > 0
                    text: root.availableWifiNetworks.length
                        + (root.availableWifiNetworks.length === 1
                            ? " network" : " networks")
                    fontColor: Settings.rosewater
                    pixelSize: Settings.fontPixelSize - 2
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.wifiError.length > 0
                implicitHeight: wifiErrorText.implicitHeight + 16
                radius: 8
                color: Settings.surface0
                border.width: 1
                border.color: Settings.red

                StyledText {
                    id: wifiErrorText

                    width: parent.width - 16
                    anchors.centerIn: parent
                    text: root.wifiError
                    fontColor: Settings.red
                    pixelSize: Settings.fontPixelSize - 1
                    txt.width: width
                    txt.wrapMode: Text.WordWrap
                }
            }

            Flickable {
                id: availableNetworkScroll

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(220, availableNetworkList.implicitHeight)
                visible: root.canScanWifi
                    && root.availableWifiNetworks.length > 0
                clip: true
                contentWidth: width
                contentHeight: availableNetworkList.implicitHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ScrollBar.vertical: ScrollBar {
                    policy: availableNetworkScroll.contentHeight
                        > availableNetworkScroll.height
                        ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ColumnLayout {
                    id: availableNetworkList

                    width: availableNetworkScroll.width
                    spacing: 4

                    Repeater {
                        model: ScriptModel {
                            values: root.availableWifiNetworks
                        }

                        delegate: WifiNetworkRow {
                            required property var modelData

                            network: modelData
                            scrollIntoView: true
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.canScanWifi
                    && root.availableWifiNetworks.length === 0
                implicitHeight: emptyNetworkText.implicitHeight + 16
                radius: 8
                color: Settings.surface0
                opacity: 0.55

                StyledText {
                    id: emptyNetworkText

                    anchors.centerIn: parent
                    text: root.searchInProgress
                        ? "Searching for Wi-Fi networks…"
                        : "Search to find available Wi-Fi networks"
                    fontColor: Settings.rosewater
                    pixelSize: Settings.fontPixelSize - 1
                }
            }
        }
    }
}
