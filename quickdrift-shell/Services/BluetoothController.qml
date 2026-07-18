pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQml.Models

Singleton {
    id: root

    property int stateRevision: 0

    readonly property var adapters: snapshotValues(Bluetooth.adapters, stateRevision)
    readonly property var devices: snapshotValues(Bluetooth.devices, stateRevision)
    readonly property var enabledAdapters: adapters.filter(adapter => adapter.state === BluetoothAdapterState.Enabled)
    readonly property var connectedDevices: devices.filter(device => device.connected)
    readonly property var pairedDevices: devices.filter(device => device.paired)

    readonly property bool available: adapters.length > 0
    readonly property bool hasEnabledAdapter: enabledAdapters.length > 0
    readonly property bool transitioning: adapters.some(adapter => adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    readonly property bool blocked: available && !hasEnabledAdapter && adapters.some(adapter => adapter.state === BluetoothAdapterState.Blocked)
    readonly property bool discovering: adapters.some(adapter => adapter.discovering)
    readonly property bool connected: connectedDevices.length > 0

    property var ownedAdapterPaths: []
    property var pendingStopAdapterPaths: []
    property int scanOwnerToken: 0
    readonly property bool scanOwned: scanOwnerToken > 0 && ownedAdapterPaths.length > 0
    readonly property bool scanStopping: pendingStopAdapterPaths.length > 0

    property string pendingPairPath: ""
    property string pendingForgetPath: ""
    property string pendingConnectionPath: ""
    property bool pendingConnectionTarget: false
    property string latestError: ""

    readonly property bool nativeOperationBusy: devices.some(device => device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
    readonly property bool busy: pendingPairPath.length > 0 || pendingForgetPath.length > 0 || pendingConnectionPath.length > 0 || nativeOperationBusy

    property int nextScanOwnerToken: 0
    property bool pairObservedActive: false
    property bool connectionObservedTransition: false

    function snapshotValues(model, _revision): var {
        return model.values.slice();
    }

    function createScanOwner(): int {
        nextScanOwnerToken += 1;
        return nextScanOwnerToken;
    }

    function ownsScan(ownerToken): bool {
        return scanOwned && scanOwnerToken === ownerToken;
    }

    function clearError(): void {
        latestError = "";
    }

    function cleanText(value): string {
        return value ? String(value).trim() : "";
    }

    function displayName(device): string {
        if (!device)
            return "Unknown device";

        const aliasName = cleanText(device.name);
        if (aliasName.length > 0)
            return aliasName;

        const reportedName = cleanText(device.deviceName);
        if (reportedName.length > 0)
            return reportedName;

        const address = cleanText(device.address);
        return address.length > 0 ? address : "Unknown device";
    }

    function adapterLabel(adapter): string {
        if (!adapter)
            return "Unknown adapter";

        const name = cleanText(adapter.name);
        if (name.length > 0)
            return name;

        const adapterId = cleanText(adapter.adapterId);
        return adapterId.length > 0 ? adapterId : "Bluetooth adapter";
    }

    function adapterByPath(path) {
        for (const adapter of Bluetooth.adapters.values) {
            if (adapter.dbusPath === path)
                return adapter;
        }

        return null;
    }

    function deviceByPath(path) {
        for (const device of Bluetooth.devices.values) {
            if (device.dbusPath === path)
                return device;
        }

        return null;
    }

    function startScan(ownerToken): bool {
        clearError();

        if (!Number.isInteger(ownerToken) || ownerToken <= 0) {
            latestError = "Could not start Bluetooth discovery.";
            return false;
        }

        if (scanOwned)
            return scanOwnerToken === ownerToken;

        if (scanStopping)
            return false;

        const candidates = enabledAdapters.filter(adapter => !adapter.discovering);
        if (candidates.length === 0) {
            if (!discovering)
                latestError = "Turn Bluetooth on before searching for devices.";
            return false;
        }

        scanOwnerToken = ownerToken;
        ownedAdapterPaths = candidates.map(adapter => adapter.dbusPath);

        const requestedPaths = [];
        for (const adapter of candidates) {
            try {
                adapter.discovering = true;
                requestedPaths.push(adapter.dbusPath);
            } catch (error) {
                console.warn("Bluetooth discovery request failed:", error);
            }
        }

        ownedAdapterPaths = requestedPaths;
        if (ownedAdapterPaths.length === 0) {
            scanOwnerToken = 0;
            latestError = "Could not start Bluetooth discovery. Try again.";
            return false;
        }

        scanStopTimer.restart();
        scanStartWatchdog.restart();
        return true;
    }

    function stopScan(ownerToken): bool {
        if (!scanOwned)
            return false;

        if (ownerToken !== undefined && (!Number.isInteger(ownerToken) || ownerToken <= 0 || ownerToken !== scanOwnerToken))
            return false;

        const paths = ownedAdapterPaths.slice();
        ownedAdapterPaths = [];
        scanOwnerToken = 0;
        scanStopTimer.stop();
        scanStartWatchdog.stop();

        const trackedPaths = paths.filter(path => adapterByPath(path));
        pendingStopAdapterPaths = pendingStopAdapterPaths.concat(trackedPaths).filter((path, index, pathsList) => pathsList.indexOf(path) === index);
        if (pendingStopAdapterPaths.length > 0)
            scanCancelWatchdog.restart();

        for (const path of trackedPaths) {
            const adapter = adapterByPath(path);
            if (!adapter.discovering)
                continue;
            try {
                adapter.discovering = false;
            } catch (error) {
                console.warn("Bluetooth discovery stop failed:", error);
            }
        }

        return true;
    }

    function removeOwnedAdapter(path): void {
        if (ownedAdapterPaths.indexOf(path) < 0)
            return;
        ownedAdapterPaths = ownedAdapterPaths.filter(candidate => candidate !== path);
        if (ownedAdapterPaths.length > 0)
            return;
        scanOwnerToken = 0;
        scanStopTimer.stop();
        scanStartWatchdog.stop();
    }

    function removePendingStopAdapter(path): void {
        if (pendingStopAdapterPaths.indexOf(path) < 0)
            return;

        pendingStopAdapterPaths = pendingStopAdapterPaths.filter(candidate => candidate !== path);
        if (pendingStopAdapterPaths.length === 0)
            scanCancelWatchdog.stop();
    }

    function pairDevice(device): bool {
        if (!device || device.paired || device.pairing)
            return false;

        if (busy) {
            latestError = "Finish the current Bluetooth action before pairing another device.";
            return false;
        }

        clearError();
        pendingPairPath = device.dbusPath;
        pairObservedActive = false;
        pairTimeout.restart();

        try {
            device.pair();
            return true;
        } catch (error) {
            console.warn("Bluetooth pairing request failed:", error);
            failPair("Could not start pairing. Try again.");
            return false;
        }
    }

    function cancelPair(device): bool {
        const target = device || deviceByPath(pendingPairPath);
        if (!target || pendingPairPath !== target.dbusPath)
            return false;

        pendingPairPath = "";
        pairObservedActive = false;
        pairTimeout.stop();
        pairCompletionGrace.stop();
        clearError();

        try {
            target.cancelPair();
            return true;
        } catch (error) {
            console.warn("Bluetooth pairing cancel failed:", error);
            latestError = "Could not cancel pairing. Try again.";
            return false;
        }
    }

    function finishPair(device): void {
        if (!device || pendingPairPath !== device.dbusPath)
            return;
        pendingPairPath = "";
        pairObservedActive = false;
        pairTimeout.stop();
        pairCompletionGrace.stop();
        clearError();

        try {
            device.trusted = true;
        } catch (error) {
            console.warn("Bluetooth trust request failed:", error);
        }

        beginConnection(device, true, true);
    }

    function failPair(message): void {
        pendingPairPath = "";
        pairObservedActive = false;
        pairTimeout.stop();
        pairCompletionGrace.stop();
        latestError = message;
    }

    function connectDevice(device): bool {
        return beginConnection(device, true, false);
    }

    function disconnectDevice(device): bool {
        return beginConnection(device, false, false);
    }

    function beginConnection(device, targetConnected, allowAfterPair): bool {
        if (!device || !device.paired)
            return false;

        if ((targetConnected && device.connected) || (!targetConnected && device.state === BluetoothDeviceState.Disconnected))
            return true;

        if (targetConnected && (!device.adapter || device.adapter.state !== BluetoothAdapterState.Enabled || device.blocked)) {
            latestError = "The device is not ready to connect. Check Bluetooth and try again.";
            return false;
        }

        if (!allowAfterPair && busy) {
            latestError = "Finish the current Bluetooth action before changing a connection.";
            return false;
        }

        clearError();
        pendingConnectionPath = device.dbusPath;
        pendingConnectionTarget = targetConnected;
        connectionObservedTransition = false;
        connectionTimeout.restart();

        try {
            if (targetConnected)
                device.connect();
            else
                device.disconnect();
        } catch (error) {
            console.warn("Bluetooth connection request failed:", error);
            failConnection(targetConnected ? "Could not connect to the device. Try again." : "Could not disconnect the device. Try again.");
            return false;
        }

        if ((targetConnected && device.connected) || (!targetConnected && device.state === BluetoothDeviceState.Disconnected)) {
            completeConnection();
        }

        return true;
    }

    function completeConnection(): void {
        pendingConnectionPath = "";
        pendingConnectionTarget = false;
        connectionObservedTransition = false;
        connectionTimeout.stop();
    }

    function failConnection(message): void {
        completeConnection();
        latestError = message;
    }

    function forgetDevice(device): bool {
        if (!device || !device.paired)
            return false;

        if (busy) {
            latestError = "Finish the current Bluetooth action before unpairing a device.";
            return false;
        }

        clearError();
        pendingForgetPath = device.dbusPath;
        forgetTimeout.restart();

        try {
            device.forget();
            return true;
        } catch (error) {
            console.warn("Bluetooth unpair request failed:", error);
            failForget("Could not unpair the device. Try again.");
            return false;
        }
    }

    function completeForget(): void {
        pendingForgetPath = "";
        forgetTimeout.stop();
    }

    function failForget(message): void {
        completeForget();
        latestError = message;
    }

    function handleAdapterStateChanged(adapter): void {
        stateRevision += 1;
        if (!adapter || adapter.state === BluetoothAdapterState.Enabled) {
            return;
        }

        removeOwnedAdapter(adapter.dbusPath);
    }

    function handleAdapterDiscoveryChanged(adapter): void {
        stateRevision += 1;
        if (!adapter)
            return;

        if (pendingStopAdapterPaths.indexOf(adapter.dbusPath) >= 0) {
            removePendingStopAdapter(adapter.dbusPath);
            if (adapter.discovering) {
                try {
                    adapter.discovering = false;
                } catch (error) {
                    console.warn("Late Bluetooth discovery stop failed:", error);
                }
            }
            return;
        }

        if (adapter.discovering && ownedAdapterPaths.indexOf(adapter.dbusPath) >= 0) {
            scanStartWatchdog.stop();
            if (latestError === "Bluetooth discovery has not started yet. You can cancel and try again.")
                clearError();
            return;
        }

        if (!adapter.discovering)
            removeOwnedAdapter(adapter.dbusPath);
    }

    function handleAdapterRemoved(path): void {
        stateRevision += 1;
        removeOwnedAdapter(path);
        removePendingStopAdapter(path);
    }

    function handleDevicePairingChanged(device): void {
        stateRevision += 1;
        if (!device || pendingPairPath !== device.dbusPath)
            return;
        if (device.pairing) {
            pairObservedActive = true;
            return;
        }

        if (device.paired && !device.pairing) {
            finishPair(device);
            return;
        }

        if (pairObservedActive)
            pairCompletionGrace.restart();
    }

    function handleDevicePairedChanged(device): void {
        stateRevision += 1;
        if (!device)
            return;
        if (pendingPairPath === device.dbusPath && device.paired && !device.pairing)
            finishPair(device);

        if (pendingForgetPath === device.dbusPath && !device.paired)
            completeForget();
    }

    function handleDeviceStateChanged(device): void {
        stateRevision += 1;
        if (!device || pendingConnectionPath !== device.dbusPath)
            return;
        if (device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting) {
            connectionObservedTransition = true;
            return;
        }

        if (pendingConnectionTarget && device.state === BluetoothDeviceState.Connected) {
            completeConnection();
            return;
        }

        if (!pendingConnectionTarget && device.state === BluetoothDeviceState.Disconnected) {
            completeConnection();
            return;
        }

        if (connectionObservedTransition) {
            failConnection(pendingConnectionTarget ? "Could not connect to the device. Try again." : "Could not disconnect the device. Try again.");
        }
    }

    function handleDeviceRemoved(path): void {
        stateRevision += 1;

        if (pendingForgetPath === path)
            completeForget();

        if (pendingPairPath === path)
            failPair("The device is no longer available. Search and try again.");

        if (pendingConnectionPath === path)
            failConnection("The device is no longer available. Search and try again.");
    }

    Timer {
        id: scanStopTimer

        interval: 20000
        repeat: false
        onTriggered: root.stopScan(root.scanOwnerToken)
    }

    Timer {
        id: scanStartWatchdog

        interval: 3000
        repeat: false
        onTriggered: {
            const activeCount = root.ownedAdapterPaths.filter(path => {
                const adapter = root.adapterByPath(path);
                return adapter && adapter.discovering;
            }).length;

            if (activeCount === 0)
                root.latestError = "Bluetooth discovery has not started yet. You can cancel and try again.";
        }
    }

    Timer {
        id: scanCancelWatchdog

        interval: 5000
        repeat: false
        onTriggered: {
            const paths = root.pendingStopAdapterPaths.slice();
            root.pendingStopAdapterPaths = [];

            for (const path of paths) {
                const adapter = root.adapterByPath(path);
                if (!adapter || !adapter.discovering)
                    continue;

                try {
                    adapter.discovering = false;
                } catch (error) {
                    console.warn("Bluetooth discovery cleanup failed:", error);
                }
            }
        }
    }

    Timer {
        id: pairTimeout

        interval: 30000
        repeat: false
        onTriggered: {
            const device = root.deviceByPath(root.pendingPairPath);
            root.pendingPairPath = "";
            root.pairObservedActive = false;
            pairCompletionGrace.stop();

            if (device && device.pairing) {
                try {
                    device.cancelPair();
                } catch (error) {
                    console.warn("Bluetooth pairing timeout cancel failed:", error);
                }
            }

            root.latestError = "Pairing timed out. Devices requiring a PIN or confirmation need a system Bluetooth agent. Try again.";
        }
    }

    Timer {
        id: pairCompletionGrace

        interval: 250
        repeat: false
        onTriggered: {
            const device = root.deviceByPath(root.pendingPairPath);
            if (device && device.paired && !device.pairing)
                root.finishPair(device);
            else
                root.failPair("Pairing was not completed. Confirm the request elsewhere if required, then try again.");
        }
    }

    Timer {
        id: connectionTimeout

        interval: 15000
        repeat: false
        onTriggered: root.failConnection(root.pendingConnectionTarget ? "Connection timed out. Try again." : "Disconnection timed out. Try again.")
    }

    Timer {
        id: forgetTimeout

        interval: 10000
        repeat: false
        onTriggered: {
            const device = root.deviceByPath(root.pendingForgetPath);
            if (!device || !device.paired)
                root.completeForget();
            else
                root.failForget("The device could not be unpaired. Try again.");
        }
    }

    Instantiator {
        model: Bluetooth.adapters

        Connections {
            required property var modelData
            property string trackedPath: ""

            target: modelData

            Component.onCompleted: {
                trackedPath = modelData.dbusPath;
                root.stateRevision += 1;
            }
            Component.onDestruction: root.handleAdapterRemoved(trackedPath)

            function onEnabledChanged(): void {
                root.stateRevision += 1;
            }

            function onStateChanged(): void {
                root.handleAdapterStateChanged(modelData);
            }

            function onDiscoveringChanged(): void {
                root.handleAdapterDiscoveryChanged(modelData);
            }

            function onNameChanged(): void {
                root.stateRevision += 1;
            }
        }
    }

    Instantiator {
        model: Bluetooth.devices

        Connections {
            required property var modelData
            property string trackedPath: ""

            target: modelData

            Component.onCompleted: {
                trackedPath = modelData.dbusPath;
                root.stateRevision += 1;
            }
            Component.onDestruction: root.handleDeviceRemoved(trackedPath)

            function onPairingChanged(): void {
                root.handleDevicePairingChanged(modelData);
            }

            function onPairedChanged(): void {
                root.handleDevicePairedChanged(modelData);
            }

            function onStateChanged(): void {
                root.handleDeviceStateChanged(modelData);
            }

            function onConnectedChanged(): void {
                root.handleDeviceStateChanged(modelData);
            }

            function onNameChanged(): void {
                root.stateRevision += 1;
            }

            function onDeviceNameChanged(): void {
                root.stateRevision += 1;
            }

            function onBatteryAvailableChanged(): void {
                root.stateRevision += 1;
            }

            function onBatteryChanged(): void {
                root.stateRevision += 1;
            }

            function onAdapterChanged(): void {
                root.stateRevision += 1;
            }
        }
    }
}
