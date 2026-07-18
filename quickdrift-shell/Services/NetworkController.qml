pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    property int modelRevision: 0
    property int adapterPresenceState: -1
    property int nextScanOwnerToken: 1
    property var ownedScannerDevices: []
    property var scanOwnerTokens: []
    property bool autoScanActive: false

    readonly property var devices: snapshotValues(Networking.devices, modelRevision)
    readonly property var wifiDevices: devices.filter(device =>
        device.type === DeviceType.Wifi)
    readonly property bool wifiAdapterPresent: wifiDevices.length > 0
    readonly property bool autoScanning: autoScanActive
        && autoScanTimer.running

    function snapshotValues(model, _revision) {
        return model.values.slice()
    }

    function syncWifiPower() {
        const nextState = wifiAdapterPresent ? 1 : 0
        if (adapterPresenceState === nextState)
            return

        adapterPresenceState = nextState
        if (!wifiAdapterPresent)
            stopAutoScan(true)

        if (Networking.wifiEnabled === wifiAdapterPresent)
            autoScanDelay.restart()
        else {
            try {
                Networking.wifiEnabled = wifiAdapterPresent
            } catch (error) {
                console.warn("Automatic Wi-Fi power request failed:", error)
            }
        }
    }

    function startAutoScan() {
        if (!wifiAdapterPresent || !Networking.wifiEnabled
                || !Networking.wifiHardwareEnabled)
            return

        autoScanActive = true
        ensureScanning()
        autoScanTimer.restart()
    }

    function stopAutoScan(forceStop = false) {
        autoScanDelay.stop()
        autoScanTimer.stop()
        autoScanActive = false

        if (forceStop || scanOwnerTokens.length === 0)
            stopOwnedScanners()
    }

    function createScanOwner() {
        const token = nextScanOwnerToken
        nextScanOwnerToken += 1
        return token
    }

    function ownsScan(ownerToken) {
        return scanOwnerTokens.indexOf(ownerToken) >= 0
    }

    function acquireScan(ownerToken) {
        if (ownerToken <= 0 || !wifiAdapterPresent
                || !Networking.wifiEnabled
                || !Networking.wifiHardwareEnabled)
            return

        if (!ownsScan(ownerToken)) {
            const owners = scanOwnerTokens.slice()
            owners.push(ownerToken)
            scanOwnerTokens = owners
        }

        ensureScanning()
    }

    function releaseScan(ownerToken) {
        const index = scanOwnerTokens.indexOf(ownerToken)
        if (index < 0)
            return

        const owners = scanOwnerTokens.slice()
        owners.splice(index, 1)
        scanOwnerTokens = owners

        if (owners.length === 0 && !autoScanActive)
            stopOwnedScanners()
    }

    function ensureScanning() {
        if (!wifiAdapterPresent || !Networking.wifiEnabled
                || !Networking.wifiHardwareEnabled)
            return

        const owned = ownedScannerDevices.filter(device =>
            device && wifiDevices.indexOf(device) >= 0)

        for (const device of wifiDevices) {
            if (device.scannerEnabled)
                continue

            try {
                device.scannerEnabled = true
                if (owned.indexOf(device) < 0)
                    owned.push(device)
            } catch (error) {
                console.warn("Wi-Fi scan request failed:", error)
            }
        }

        ownedScannerDevices = owned
    }

    function stopOwnedScanners() {
        const devicesToStop = ownedScannerDevices.slice()
        ownedScannerDevices = []

        for (const device of devicesToStop) {
            if (!device || !device.scannerEnabled)
                continue

            try {
                device.scannerEnabled = false
            } catch (error) {
                console.warn("Wi-Fi scan stop failed:", error)
            }
        }
    }

    Timer {
        id: adapterPresenceTimer

        interval: 150
        repeat: false
        onTriggered: root.syncWifiPower()
    }

    Timer {
        id: autoScanDelay

        interval: 150
        repeat: false
        onTriggered: root.startAutoScan()
    }

    Timer {
        id: autoScanTimer

        interval: 5000
        repeat: false
        onTriggered: root.stopAutoScan(false)
    }

    Connections {
        target: Networking.devices

        function onValuesChanged(): void {
            root.modelRevision += 1
            adapterPresenceTimer.restart()
        }
    }

    Connections {
        target: Networking

        function onWifiEnabledChanged(): void {
            if (Networking.wifiEnabled && root.wifiAdapterPresent)
                autoScanDelay.restart()
            else
                root.stopAutoScan(true)
        }

        function onWifiHardwareEnabledChanged(): void {
            if (Networking.wifiHardwareEnabled && Networking.wifiEnabled
                    && root.wifiAdapterPresent) {
                autoScanDelay.restart()
            } else {
                root.stopAutoScan(true)
            }
        }
    }

    Component.onCompleted: adapterPresenceTimer.start()
    Component.onDestruction: stopAutoScan(true)
}
