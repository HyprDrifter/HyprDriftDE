pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Internal

Singleton {
    id: root

    property real cpuUsage: -1
    property real ramUsedGiB: -1
    property real gpuUsage: -1

    property real previousCpuTotal: -1
    property real previousCpuIdle: -1
    property bool cpuReadPending: true
    property bool ramReadPending: true

    property string gpuBackend: "discovering"
    property string gpuSysfsPath: ""
    property var gpuSysfsCandidates: []
    property int gpuProbeIndex: -1
    property bool gpuDiscoveryComplete: false
    property bool gpuReadPending: false

    function updateCpu(contents) {
        const firstLineEnd = contents.indexOf("\n")
        const firstLine = (firstLineEnd >= 0
            ? contents.slice(0, firstLineEnd)
            : contents).trim()
        const fields = firstLine.split(/\s+/)

        if (fields.length < 5 || fields[0] !== "cpu")
            return

        const values = []
        for (let index = 1; index < fields.length; ++index) {
            const value = Number(fields[index])
            if (!Number.isFinite(value) || value < 0)
                return
            values.push(value)
        }

        while (values.length < 8)
            values.push(0)

        const idle = values[3] + values[4]
        const nonIdle = values[0] + values[1] + values[2]
            + values[5] + values[6] + values[7]
        const total = idle + nonIdle

        if (previousCpuTotal >= 0 && previousCpuIdle >= 0) {
            const totalDelta = total - previousCpuTotal
            const idleDelta = idle - previousCpuIdle

            if (totalDelta > 0 && idleDelta >= 0 && idleDelta <= totalDelta) {
                const busy = 100 * (totalDelta - idleDelta) / totalDelta
                cpuUsage = Math.max(0, Math.min(100, busy))
            }
        }

        previousCpuTotal = total
        previousCpuIdle = idle
    }

    function updateRam(contents) {
        const values = ({})
        const lines = contents.split("\n")

        for (const line of lines) {
            const match = /^([^:]+):\s+([0-9]+)/.exec(line)
            if (match)
                values[match[1]] = Number(match[2])
        }

        const total = values.MemTotal
        if (!Number.isFinite(total) || total <= 0)
            return

        let available = values.MemAvailable
        if (!Number.isFinite(available)) {
            available = (values.MemFree || 0)
                + (values.Buffers || 0)
                + (values.Cached || 0)
                + (values.SReclaimable || 0)
                - (values.Shmem || 0)
        }

        if (!Number.isFinite(available))
            return

        const used = Math.max(0, Math.min(total, total - available))
        ramUsedGiB = used / 1048576
    }

    function parseGpuUsage(contents) {
        const valueText = contents.trim()
        if (!/^[0-9]+([.][0-9]+)?$/.test(valueText))
            return -1

        const value = Number(valueText)
        return Number.isFinite(value) && value >= 0 && value <= 100 ? value : -1
    }

    function handleGpuDiscoveryResult(contents) {
        const configuredPath = Settings.gpuBusyPath.trim()
        const discoveredPaths = contents.split("\n").map(path => path.trim()).filter(path =>
            /^\/sys\/class\/drm\/card[0-9]+\/device\/gpu_busy_percent$/.test(path))

        discoveredPaths.sort((left, right) => {
            const leftCard = Number(/card([0-9]+)/.exec(left)[1])
            const rightCard = Number(/card([0-9]+)/.exec(right)[1])
            return leftCard - rightCard
        })

        const candidates = []
        if (configuredPath !== "")
            candidates.push(configuredPath)

        for (const path of discoveredPaths) {
            if (candidates.indexOf(path) < 0)
                candidates.push(path)
        }

        gpuSysfsCandidates = candidates
        gpuProbeIndex = 0

        if (candidates.length === 0) {
            gpuDiscoveryComplete = true
            startNvidiaMonitor()
            return
        }

        probeCurrentGpuCandidate()
    }

    function probeCurrentGpuCandidate() {
        if (gpuDiscoveryComplete || gpuProbeIndex < 0
                || gpuProbeIndex >= gpuSysfsCandidates.length)
            return

        gpuReadPending = true
        gpuSysfsPath = gpuSysfsCandidates[gpuProbeIndex]
    }

    function advanceGpuProbe() {
        gpuReadPending = false
        gpuSysfsPath = ""
        ++gpuProbeIndex

        if (gpuProbeIndex >= gpuSysfsCandidates.length) {
            gpuDiscoveryComplete = true
            startNvidiaMonitor()
            return
        }

        Qt.callLater(() => root.probeCurrentGpuCandidate())
    }

    function handleSysfsGpuLoaded(contents) {
        const value = parseGpuUsage(contents)

        if (!gpuDiscoveryComplete) {
            if (value < 0) {
                advanceGpuProbe()
                return
            }

            gpuDiscoveryComplete = true
            gpuBackend = "sysfs"
            gpuUsage = value
        } else if (gpuBackend === "sysfs" && value >= 0) {
            gpuUsage = value
        }

        gpuReadPending = false
    }

    function handleSysfsGpuFailure() {
        if (!gpuDiscoveryComplete)
            advanceGpuProbe()
        else
            gpuReadPending = false
    }

    function updateNvidiaGpu(contents) {
        const value = parseGpuUsage(contents)
        if (value < 0)
            return

        gpuBackend = "nvidia"
        gpuUsage = value
        gpuSysfsPath = ""
        gpuReadPending = false
    }

    function startNvidiaMonitor() {
        if (nvidiaMonitor.running)
            return

        gpuBackend = "nvidia-starting"
        nvidiaMonitor.running = true
    }

    function handleNvidiaExit() {
        if (gpuBackend === "nvidia" || gpuBackend === "nvidia-starting")
            gpuBackend = "unsupported"
    }

    FileView {
        id: cpuStat
        path: "/proc/stat"
        printErrors: false

        onLoaded: {
            root.updateCpu(cpuStat.text())
            root.cpuReadPending = false
        }

        onLoadFailed: error => root.cpuReadPending = false
    }

    FileView {
        id: memoryInfo
        path: "/proc/meminfo"
        printErrors: false

        onLoaded: {
            root.updateRam(memoryInfo.text())
            root.ramReadPending = false
        }

        onLoadFailed: error => root.ramReadPending = false
    }

    FileView {
        id: gpuStats
        path: root.gpuSysfsPath
        printErrors: false

        onLoaded: root.handleSysfsGpuLoaded(gpuStats.text())
        onLoadFailed: error => root.handleSysfsGpuFailure()
    }

    Process {
        id: gpuSysfsDiscovery
        property string output: ""
        property bool outputReady: false
        property bool exitReceived: false
        property bool handled: false

        running: true
        command: [
            "find", "-L", "/sys/class/drm",
            "-maxdepth", "3",
            "-type", "f",
            "-name", "gpu_busy_percent",
            "-print"
        ]

        function finishIfReady() {
            if (handled || !outputReady || !exitReceived)
                return

            handled = true
            root.handleGpuDiscoveryResult(output)
        }

        onExited: (exitCode, exitStatus) => {
            exitReceived = true
            finishIfReady()
        }

        stdout: StdioCollector {
            onStreamFinished: {
                gpuSysfsDiscovery.output = this.text
                gpuSysfsDiscovery.outputReady = true
                gpuSysfsDiscovery.finishIfReady()
            }
        }

        stderr: SplitParser {}
    }

    Process {
        id: nvidiaMonitor
        running: false
        command: [
            "nvidia-smi",
            "--query-gpu=utilization.gpu",
            "--format=csv,noheader,nounits",
            "--id=0",
            "--loop-ms=" + Math.max(1, Settings.gpuRefreshRate)
        ]

        stdout: SplitParser {
            onRead: data => root.updateNvidiaGpu(data)
        }

        stderr: SplitParser {}

        onExited: (exitCode, exitStatus) => root.handleNvidiaExit()
    }

    Timer {
        interval: Math.max(1, Settings.cpuRefreshRate)
        running: true
        repeat: true

        onTriggered: {
            if (!root.cpuReadPending) {
                root.cpuReadPending = true
                cpuStat.reload()
            }
        }
    }

    Timer {
        interval: Math.max(1, Settings.ramRefreshRate)
        running: true
        repeat: true

        onTriggered: {
            if (!root.ramReadPending) {
                root.ramReadPending = true
                memoryInfo.reload()
            }
        }
    }

    Timer {
        interval: Math.max(1, Settings.gpuRefreshRate)
        running: true
        repeat: true

        onTriggered: {
            if (root.gpuBackend === "sysfs" && !root.gpuReadPending) {
                root.gpuReadPending = true
                gpuStats.reload()
            }
        }
    }
}
