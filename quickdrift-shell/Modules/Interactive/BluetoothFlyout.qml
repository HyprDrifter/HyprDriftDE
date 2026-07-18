pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

PopupWindow {
    id: root

    required property Item moveToItem

    property int scanOwnerToken: 0
    property bool pointerHasEntered: false
    property bool geometryAnimationsEnabled: false
    readonly property var adapters: BluetoothController.adapters
    readonly property var devices: BluetoothController.devices
    readonly property var pairedDevices: devices.filter(device => device.paired).sort((left, right) => {
        if (left.connected !== right.connected)
            return left.connected ? -1 : 1;
        return BluetoothController.displayName(left).localeCompare(BluetoothController.displayName(right));
    })
    readonly property var availableDevices: devices.filter(device => !device.paired).sort((left, right) => {
        if (left.pairing !== right.pairing)
            return left.pairing ? -1 : 1;
        return BluetoothController.displayName(left).localeCompare(BluetoothController.displayName(right));
    })
    readonly property bool multipleAdapters: adapters.length > 1
    readonly property bool ownsScan: BluetoothController.ownsScan(scanOwnerToken)
    readonly property bool canStartScan: BluetoothController.enabledAdapters.some(adapter => !adapter.discovering)
    readonly property string overallStatus: {
        if (!BluetoothController.available)
            return "Unavailable";
        if (BluetoothController.connected) {
            const count = BluetoothController.connectedDevices.length;
            return count === 1 ? "1 connected" : count + " connected";
        }
        if (BluetoothController.scanStopping)
            return "Stopping";
        if (BluetoothController.discovering)
            return "Searching";
        if (BluetoothController.transitioning)
            return "Transitioning";
        if (BluetoothController.blocked)
            return "Blocked";
        if (BluetoothController.hasEnabledAdapter)
            return "Ready";
        return "Disabled";
    }
    readonly property color overallStatusColor: {
        if (BluetoothController.connected)
            return Settings.green;
        if (BluetoothController.scanStopping)
            return Settings.yellow;
        if (BluetoothController.discovering)
            return Settings.blue;
        if (BluetoothController.transitioning)
            return Settings.yellow;
        if (!BluetoothController.available || BluetoothController.blocked || !BluetoothController.hasEnabledAdapter) {
            return Settings.red;
        }
        return Settings.teal;
    }
    readonly property string statusDetail: {
        if (!BluetoothController.available)
            return "No Bluetooth adapter is available.";
        if (BluetoothController.blocked)
            return "Bluetooth is blocked by the system and cannot search for devices.";
        if (BluetoothController.transitioning) {
            const turningOn = adapters.some(adapter => adapter.state === BluetoothAdapterState.Enabling);
            return turningOn ? "Bluetooth is turning on." : "Bluetooth is turning off.";
        }
        if (!BluetoothController.hasEnabledAdapter)
            return "Bluetooth is off. Turn it on in system settings to search.";
        if (BluetoothController.scanStopping)
            return "Waiting for Bluetooth discovery to stop safely.";
        if (BluetoothController.discovering) {
            const adapterCount = BluetoothController.enabledAdapters.length;
            return "Searching on " + adapterCount + " enabled adapter" + (adapterCount === 1 ? "." : "s.");
        }
        if (BluetoothController.connected) {
            const count = BluetoothController.connectedDevices.length;
            return count + " device" + (count === 1 ? " is" : "s are") + " currently connected.";
        }
        return "Search to refresh devices currently tracked by BlueZ.";
    }
    readonly property string scanButtonText: {
        if (ownsScan)
            return BluetoothController.discovering ? "Stop search" : "Cancel search";
        if (BluetoothController.scanStopping)
            return "Stopping…";
        if (BluetoothController.scanOwned || BluetoothController.discovering) {
            return "Searching…";
        }
        return "Search for devices";
    }

    property string confirmForgetPath: ""
    property string focusAfterPairPath: ""
    property bool closing: false
    property real flyoutOpacity: 0
    property real flyoutScale: 0.9
    property real flyoutOffset: -18
    property real contentOpacity: 0
    property real contentOffset: 8
    property real accentProgress: 0

    readonly property int anchorGap: 8
    readonly property bool verticalAnchor: moveToItem.parent ? moveToItem.parent.height > moveToItem.parent.width : false

    signal forgetConfirmationCancelled(path: string)

    function deviceStateText(device): string {
        if (!device)
            return "Unavailable";
        if (BluetoothController.pendingForgetPath === device.dbusPath)
            return "Unpairing";
        if (BluetoothController.pendingPairPath === device.dbusPath || device.pairing) {
            return "Pairing";
        }

        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        case BluetoothDeviceState.Disconnected:
            return device.paired ? "Paired" : "Available";
        default:
            return "Unknown";
        }
    }

    function deviceStateColor(device): color {
        if (!device)
            return Settings.red;
        if (device.connected)
            return Settings.green;
        if (device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting || BluetoothController.pendingForgetPath === device.dbusPath) {
            return Settings.yellow;
        }
        return device.paired ? Settings.teal : Settings.rosewater;
    }

    function deviceAdapterReady(device): bool {
        return device && device.adapter && device.adapter.state === BluetoothAdapterState.Enabled;
    }

    function sanitizeConfirmation(): void {
        if (confirmForgetPath.length === 0)
            return;
        const device = BluetoothController.deviceByPath(confirmForgetPath);
        if (!device || !device.paired)
            confirmForgetPath = "";
    }

    function cancelForgetConfirmation(restoreFocus): void {
        const path = confirmForgetPath;
        confirmForgetPath = "";
        if (restoreFocus && path.length > 0)
            forgetConfirmationCancelled(path);
    }

    function ensureDeviceActionVisible(item): void {
        if (!item)
            return;

        const position = item.mapToItem(deviceSections, 0, 0);
        const margin = 8;
        const top = Math.max(0, position.y - margin);
        const bottom = position.y + item.height + margin;

        if (top < deviceScroll.contentY) {
            deviceScroll.contentY = top;
        } else if (bottom > deviceScroll.contentY + deviceScroll.height) {
            deviceScroll.contentY = Math.min(Math.max(0, deviceScroll.contentHeight - deviceScroll.height), bottom - deviceScroll.height);
        }
    }

    function resetAnimationState(): void {
        flyoutOpacity = 0;
        flyoutScale = 0.9;
        flyoutOffset = -18;
        contentOpacity = 0;
        contentOffset = 8;
        accentProgress = 0;
    }

    function focusInitialControl(): void {
        if (scanButton.enabled)
            scanButton.forceActiveFocus();
        else
            card.forceActiveFocus();
    }

    function reveal(): void {
        hoverDismissTimer.stop();

        if (visible) {
            if (closing) {
                closeAnimation.stop();
                closing = false;
                geometryAnimationsEnabled = false;
                openAnimation.restart();
                Qt.callLater(focusInitialControl);
            }
            return;
        }

        visible = true;
    }

    function dismiss(): void {
        if (!visible || closing)
            return;
        hoverDismissTimer.stop();
        BluetoothController.stopScan(scanOwnerToken);
        openAnimation.stop();
        closing = true;
        geometryAnimationsEnabled = false;
        closeAnimation.restart();
    }

    function cancelPointerDismiss(): void {
        pointerHasEntered = true;
        hoverDismissTimer.stop();
    }

    function schedulePointerDismiss(): void {
        if (visible && !closing && pointerHasEntered)
            hoverDismissTimer.restart();
    }

    function toggle(): void {
        if (visible)
            dismiss();
        else
            reveal();
    }

    visible: false
    grabFocus: false
    color: "transparent"
    implicitWidth: 380
    implicitHeight: Math.min(560, Math.max(260, headerBlock.implicitHeight + Math.min(deviceSections.implicitHeight, 350) + 50))

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
            hoverDismissTimer.stop();
            pointerHasEntered = false;
            closing = false;
            geometryAnimationsEnabled = false;
            resetAnimationState();
            openAnimation.restart();
            Qt.callLater(focusInitialControl);
        } else {
            hoverDismissTimer.stop();
            pointerHasEntered = false;
            BluetoothController.stopScan(scanOwnerToken);
            confirmForgetPath = "";
            openAnimation.stop();
            closeAnimation.stop();
            closing = false;
            geometryAnimationsEnabled = false;
            resetAnimationState();
        }
    }

    Component.onCompleted: scanOwnerToken = BluetoothController.createScanOwner()
    Component.onDestruction: BluetoothController.stopScan(scanOwnerToken)

    Connections {
        target: BluetoothController

        function onStateRevisionChanged(): void {
            root.sanitizeConfirmation();
        }

        function onPendingPairPathChanged(): void {
            if (BluetoothController.pendingPairPath.length > 0 || root.focusAfterPairPath.length === 0) {
                return;
            }

            const device = BluetoothController.deviceByPath(root.focusAfterPairPath);
            if (!device || !device.paired)
                root.focusAfterPairPath = "";
        }

        function onPendingForgetPathChanged(): void {
            if (BluetoothController.pendingForgetPath.length > 0 || root.confirmForgetPath.length === 0) {
                return;
            }

            const device = BluetoothController.deviceByPath(root.confirmForgetPath);
            if (!device || !device.paired) {
                root.confirmForgetPath = "";
                Qt.callLater(root.focusInitialControl);
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: root.visible && !root.closing
        windows: [root]

        onCleared: {
            if (root.visible && !root.closing)
                root.dismiss();
        }
    }

    Timer {
        id: hoverDismissTimer

        interval: 180
        repeat: false
        onTriggered: root.dismiss()
    }

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
                root.geometryAnimationsEnabled = true;
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

        onFinished: root.visible = false
    }

    component ActionButton: Button {
        id: control

        property color accentColor: Settings.blue
        property bool destructive: false
        property bool keepVisibleOnFocus: false

        activeFocusOnTab: enabled
        implicitWidth: Math.max(74, buttonLabel.implicitWidth + 20)
        implicitHeight: 32

        Accessible.name: text

        onActiveFocusChanged: {
            if (activeFocus && keepVisibleOnFocus)
                root.ensureDeviceActionVisible(control);
        }

        contentItem: Text {
            id: buttonLabel

            text: control.text
            color: control.enabled ? control.destructive ? Settings.red : Settings.text : Settings.rosewater
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontPixelSize - 1
            font.bold: false
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 7
            color: {
                if (!control.enabled)
                    return Settings.surface0;
                if (control.down)
                    return Settings.mantle;
                if (control.hovered || control.visualFocus)
                    return Settings.surface1;
                return Settings.surface0;
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

    component DeviceRow: Rectangle {
        id: deviceRow

        required property var device

        readonly property string path: device ? device.dbusPath : ""
        readonly property string displayName: BluetoothController.displayName(device)
        readonly property bool pendingPair: BluetoothController.pendingPairPath === path
        readonly property bool pendingForget: BluetoothController.pendingForgetPath === path
        readonly property bool pendingConnection: BluetoothController.pendingConnectionPath === path
        readonly property bool confirmingForget: root.confirmForgetPath === path
        readonly property bool deviceTransitioning: device && (device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
        readonly property string iconSource: {
            if (!device)
                return "";
            const iconName = BluetoothController.cleanText(device.icon);
            return Quickshell.iconPath(iconName.length > 0 ? iconName : "bluetooth", "bluetooth");
        }
        readonly property string connectionButtonText: {
            if (pendingConnection || device.state === BluetoothDeviceState.Connecting) {
                return "Connecting…";
            }
            if (device.state === BluetoothDeviceState.Disconnecting)
                return "Disconnecting…";
            return device.connected ? "Disconnect" : "Connect";
        }

        Layout.fillWidth: true
        implicitHeight: deviceContent.implicitHeight + 20
        radius: 9
        color: Settings.surface0
        border.width: device.connected || pendingPair || pendingForget || pendingConnection ? 1 : 0
        border.color: device.connected ? Settings.green : pendingForget ? Settings.red : Settings.blue

        Behavior on y {
            enabled: root.geometryAnimationsEnabled

            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Component.onCompleted: {
            if (device.paired && root.focusAfterPairPath === deviceRow.path) {
                root.focusAfterPairPath = "";
                Qt.callLater(() => connectionButton.forceActiveFocus());
            }
        }

        Connections {
            target: root

            function onForgetConfirmationCancelled(path): void {
                if (path === deviceRow.path)
                    Qt.callLater(() => unpairButton.forceActiveFocus());
            }
        }

        ColumnLayout {
            id: deviceContent

            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: deviceRow.device.connected ? Settings.green : Settings.mantle
                        opacity: deviceRow.device.connected ? 0.2 : 0.9
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: deviceRow.device.connected ? Settings.bluetoothConnectedIcon : Settings.bluetoothEnabledIcon
                        fontColor: deviceRow.device.connected ? Settings.green : Settings.text
                        pixelSize: 17
                        visible: deviceRow.iconSource.length === 0
                    }

                    IconImage {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: deviceRow.iconSource
                        visible: deviceRow.iconSource.length > 0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: deviceRow.displayName
                        fontColor: Settings.text
                        bold: true
                        txt.width: width
                        txt.elide: Text.ElideRight
                        txt.maximumLineCount: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: BluetoothController.cleanText(deviceRow.device.address).length > 0 ? deviceRow.device.address : "Address unavailable"
                        fontColor: Settings.rosewater
                        pixelSize: Settings.fontPixelSize - 2
                        txt.width: width
                        txt.elide: Text.ElideRight
                        txt.maximumLineCount: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.multipleAdapters
                        text: BluetoothController.adapterLabel(deviceRow.device.adapter)
                        fontColor: Settings.rosewater
                        pixelSize: Settings.fontPixelSize - 2
                        txt.width: width
                        txt.elide: Text.ElideRight
                        txt.maximumLineCount: 1
                    }
                }

                StyledText {
                    visible: deviceRow.device.batteryAvailable
                    text: Math.round(Math.max(0, Math.min(1, deviceRow.device.battery)) * 100) + "%"
                    fontColor: Settings.green
                    pixelSize: Settings.fontPixelSize - 1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                StyledText {
                    text: root.deviceStateText(deviceRow.device)
                    fontColor: root.deviceStateColor(deviceRow.device)
                    pixelSize: Settings.fontPixelSize - 1
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    id: pairButton

                    visible: !deviceRow.device.paired
                    text: deviceRow.pendingPair ? "Cancel" : deviceRow.device.pairing ? "Pairing…" : "Pair"
                    enabled: deviceRow.pendingPair || (!deviceRow.device.pairing && !BluetoothController.busy && !deviceRow.device.blocked && root.deviceAdapterReady(deviceRow.device))
                    keepVisibleOnFocus: true

                    onClicked: {
                        if (deviceRow.pendingPair) {
                            BluetoothController.cancelPair(deviceRow.device);
                        } else {
                            root.focusAfterPairPath = deviceRow.path;
                            if (!BluetoothController.pairDevice(deviceRow.device)) {
                                root.focusAfterPairPath = "";
                            }
                        }
                    }
                }

                ActionButton {
                    id: connectionButton

                    visible: deviceRow.device.paired && !deviceRow.confirmingForget
                    text: deviceRow.connectionButtonText
                    enabled: !BluetoothController.busy && !deviceRow.deviceTransitioning && !deviceRow.pendingForget && !deviceRow.device.blocked && root.deviceAdapterReady(deviceRow.device)
                    keepVisibleOnFocus: true

                    onClicked: {
                        if (deviceRow.device.connected)
                            BluetoothController.disconnectDevice(deviceRow.device);
                        else
                            BluetoothController.connectDevice(deviceRow.device);
                    }
                }

                ActionButton {
                    id: unpairButton

                    visible: deviceRow.device.paired && !deviceRow.confirmingForget
                    text: deviceRow.pendingForget ? "Unpairing…" : "Unpair"
                    destructive: true
                    enabled: !BluetoothController.busy && !deviceRow.deviceTransitioning
                    keepVisibleOnFocus: true

                    onClicked: {
                        root.confirmForgetPath = deviceRow.path;
                        Qt.callLater(() => cancelForgetButton.forceActiveFocus());
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: deviceRow.confirmingForget
                text: "Unpair " + deviceRow.displayName + "? This removes its saved pairing."
                fontColor: Settings.rosewater
                pixelSize: Settings.fontPixelSize - 1
                txt.width: width
                txt.wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                visible: deviceRow.confirmingForget
                spacing: 7

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    id: cancelForgetButton

                    text: "Cancel"
                    enabled: !deviceRow.pendingForget
                    keepVisibleOnFocus: true

                    onClicked: root.cancelForgetConfirmation(true)
                }

                ActionButton {
                    id: confirmForgetButton

                    text: deviceRow.pendingForget ? "Unpairing…" : "Confirm unpair"
                    destructive: true
                    enabled: !BluetoothController.busy
                    keepVisibleOnFocus: true

                    onClicked: BluetoothController.forgetDevice(deviceRow.device)
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
                    root.cancelPointerDismiss();
                else
                    root.schedulePointerDismiss();
            }
        }

        transform: Translate {
            y: root.flyoutOffset
        }

        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Escape)
                return;
            if (root.confirmForgetPath.length > 0 && BluetoothController.pendingForgetPath !== root.confirmForgetPath) {
                root.cancelForgetConfirmation(true);
            } else {
                root.dismiss();
            }
            event.accepted = true;
        }

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, (parent.width - 28) * root.accentProgress)
            height: 2
            radius: 1
            color: root.overallStatusColor
            opacity: 0.9 * root.flyoutOpacity
        }

        Item {
            id: contentTransform

            anchors.fill: parent
            anchors.margins: 12
            opacity: root.contentOpacity

            transform: Translate {
                y: root.contentOffset
            }

            ColumnLayout {
                id: panelContent

                anchors.fill: parent
                spacing: 10

                ColumnLayout {
                    id: headerBlock

                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: "Bluetooth"
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
                        Layout.fillWidth: true
                        text: root.statusDetail
                        fontColor: Settings.rosewater
                        pixelSize: Settings.fontPixelSize - 1
                        txt.width: width
                        txt.wrapMode: Text.WordWrap
                    }

                    ActionButton {
                        id: scanButton

                        Layout.fillWidth: true
                        text: root.scanButtonText
                        accentColor: Settings.blue
                        enabled: root.ownsScan || (!BluetoothController.scanOwned && !BluetoothController.scanStopping && root.canStartScan && !BluetoothController.busy)

                        onClicked: {
                            if (root.ownsScan)
                                BluetoothController.stopScan(root.scanOwnerToken);
                            else
                                BluetoothController.startScan(root.scanOwnerToken);
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: errorContent.implicitHeight + 14
                        visible: BluetoothController.latestError.length > 0
                        radius: 8
                        color: Settings.surface0
                        border.width: 1
                        border.color: Settings.red

                        RowLayout {
                            id: errorContent

                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 8

                            StyledText {
                                Layout.fillWidth: true
                                text: BluetoothController.latestError
                                fontColor: Settings.rosewater
                                pixelSize: Settings.fontPixelSize - 1
                                txt.width: width
                                txt.wrapMode: Text.WordWrap
                            }

                            ActionButton {
                                text: "Dismiss"
                                implicitWidth: 72

                                onClicked: BluetoothController.clearError()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Settings.surface1
                    }
                }

                Flickable {
                    id: deviceScroll

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: deviceSections.implicitHeight
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    pixelAligned: true

                    ScrollBar.vertical: ScrollBar {
                        policy: deviceSections.implicitHeight > deviceScroll.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    }

                    ColumnLayout {
                        id: deviceSections

                        width: Math.max(0, deviceScroll.width - 8)
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: "Paired devices"
                                fontColor: Settings.text
                                bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: String(root.pairedDevices.length)
                                fontColor: Settings.rosewater
                                pixelSize: Settings.fontPixelSize - 1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: root.pairedDevices.length === 0
                            text: "No paired devices"
                            fontColor: Settings.rosewater
                            pixelSize: Settings.fontPixelSize - 1
                        }

                        Repeater {
                            model: ScriptModel {
                                values: root.pairedDevices
                            }

                            delegate: DeviceRow {
                                required property var modelData

                                device: modelData
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Settings.surface1
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: "Available devices"
                                fontColor: Settings.text
                                bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: String(root.availableDevices.length)
                                fontColor: Settings.rosewater
                                pixelSize: Settings.fontPixelSize - 1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: root.availableDevices.length === 0
                            text: BluetoothController.discovering ? "Searching for devices…" : "No unpaired devices found"
                            fontColor: Settings.rosewater
                            pixelSize: Settings.fontPixelSize - 1
                        }

                        Repeater {
                            model: ScriptModel {
                                values: root.availableDevices
                            }

                            delegate: DeviceRow {
                                required property var modelData

                                device: modelData
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: "BlueZ may keep previously discovered devices in this list."
                            fontColor: Settings.rosewater
                            pixelSize: Settings.fontPixelSize - 2
                            txt.width: width
                            txt.wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
