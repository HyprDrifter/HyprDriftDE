pragma Singleton
pragma ComponentBehavior: Bound
import qs.Internal
import qs.Services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    readonly property bool ready: sink?.ready ?? false
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property int observedVolumePercent: -1
    property bool observedMuted: false
    property bool systemStateRefreshQueued: false

    readonly property int currentVolume: observedVolumePercent >= 0
        ? observedVolumePercent
        : sink?.audio
            ? Math.round(sink.audio.volume * 100)
            : 0
    readonly property bool muted: observedVolumePercent >= 0
        ? observedMuted
        : sink?.audio?.muted ?? false
    readonly property var pipewireNodes: Pipewire.nodes.values
    readonly property var playbackStreams: pipewireNodes.filter(
        node => root.isPlaybackStream(node)
    )
    property var applicationStreams: []
    property var pendingStreamCandidates: ({})
    property bool audioOnCooldown: false

    signal sinkProtectionTriggered(string reason)

    PwObjectTracker {
        // A PwNode must be bound before its media.class, volume, and mute
        // properties can be read or changed reliably. Track the complete live
        // model so newly created and removed application streams reconcile
        // without application-specific matching.
        objects: root.pipewireNodes
    }

    function isPlaybackStream(node): bool {
        if (!node || !node.audio)
            return false

        const mediaClass = String(
            node.properties?.["media.class"] || node.type || "")
        return mediaClass === "Stream/Output/Audio"
    }

    function reconcileApplicationStreams(): void {
        const now = Date.now()
        const minimumLifetime = Math.max(0,
            Settings.audioStreamMinimumLifetimeMs)
        const eligibleById = ({})
        const nextEligible = []
        const nextPending = ({})
        let nextDelay = minimumLifetime

        for (const node of applicationStreams) {
            if (node)
                eligibleById[String(node.id)] = node
        }

        for (const node of playbackStreams) {
            const key = String(node.id)

            // Once promoted, retain the channel until Pipewire removes that
            // exact node. A reused node ID must earn its own lifetime.
            if (eligibleById[key] === node) {
                nextEligible.push(node)
                continue
            }

            const previous = pendingStreamCandidates[key]
            const firstSeen = previous?.node === node
                ? previous.firstSeen
                : now
            const age = now - firstSeen

            if (age >= minimumLifetime) {
                nextEligible.push(node)
            } else {
                nextPending[key] = ({ node: node, firstSeen: firstSeen })
                nextDelay = Math.min(nextDelay, minimumLifetime - age)
            }
        }

        applicationStreams = nextEligible
        pendingStreamCandidates = nextPending

        if (Object.keys(nextPending).length > 0) {
            eligibilityTimer.interval = Math.max(1, Math.ceil(nextDelay))
            eligibilityTimer.restart()
        } else {
            eligibilityTimer.stop()
        }
    }

    function setMasterVolumePercent(percent): void {
        if (!sink?.audio)
            return

        const previousPercent = currentVolume
        const maximum = Settings.audioProtection
            ? Settings.audioMaxVolume
            : 200
        const safePercent = Math.max(0,
            Math.min(maximum, Number(percent) || 0))
        observedVolumePercent = Math.round(safePercent)
        sink.audio.volume = safePercent / 100

        if (observedVolumePercent !== previousPercent)
            playVolumeFeedback()
    }

    function adjustMasterVolume(deltaPercent): void {
        setMasterVolumePercent(currentVolume + deltaPercent)
    }

    function toggleMasterMute(): void {
        if (!sink?.audio)
            return

        observedMuted = !muted
        observedVolumePercent = Math.max(0, currentVolume)
        sink.audio.muted = observedMuted
    }

    function scheduleSystemStateRefresh(): void {
        systemStateRefreshTimer.restart()
    }

    function playVolumeFeedback(): void {
        if (audioOnCooldown)
            return

        AudioPlayback.play(Settings.systemAudioVolumeChange)
        audioOnCooldown = true
        audioCooldownTimer.restart()
    }

    function refreshSystemState(): void {
        if (systemStateQuery.running) {
            systemStateRefreshQueued = true
            return
        }

        systemStateRefreshQueued = false
        systemStateQuery.running = true
    }

    function applySystemState(output): void {
        const text = String(output || "")
        const match = /Volume:\s*([0-9]+(?:[.][0-9]+)?)/.exec(text)
        if (!match)
            return

        const volume = Number(match[1])
        if (!Number.isFinite(volume))
            return

        const previousObservedPercent = observedVolumePercent
        let percent = Math.max(0, Math.round(volume * 100))
        const isMuted = /\[MUTED\]/.test(text)

        if (Settings.audioProtection && percent > Settings.audioMaxVolume) {
            percent = Settings.audioMaxVolume
            setMasterVolumePercent(percent)
        }

        observedVolumePercent = percent
        observedMuted = isMuted

        if (previousObservedPercent >= 0
                && previousObservedPercent !== percent)
            playVolumeFeedback()
    }

    function handleSystemStateEvent(line): void {
        const event = String(line || "")
        if (/\bon (?:sink|server)(?:\s|#|$)/.test(event))
            scheduleSystemStateRefresh()
    }

    Connections {

        target: root.sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {

            if (!lastReady) {
                lastVolume = root.sink.audio.volume;
                lastReady = true;
                return;
            }
            root.playVolumeFeedback();
            if (!Settings.audioProtection) {
                lastVolume = root.sink.audio.volume;
                return;
            }
            const newVolume = root.sink.audio.volume;
            const maxAllowedIncrease = Settings.audioMaxIncrease / 100;
            const maxAllowed = Settings.audioMaxVolume / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                root.sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered("Illegal increment");
            } else if (newVolume <= 0) {
                if (!root.sink.ready) {return;}
                root.sink.audio.volume = 0;
                root.sinkProtectionTriggered("Exceeded max allowed");
            } else if (newVolume > maxAllowed) {
                if (!root.sink.ready) {return;}
                root.sink.audio.volume = maxAllowed;
                root.sinkProtectionTriggered("Exceeded max allowed");
            } 
            lastVolume = Math.round(root.sink.audio.volume * 100) / 100;
        }
    }

    Timer{
        id: audioCooldownTimer
        interval: 100
        running: false
        onTriggered: {
            root.audioOnCooldown = false
        }
    }

    Timer {
        id: eligibilityTimer

        repeat: false
        onTriggered: root.reconcileApplicationStreams()
    }

    Process {
        id: systemStateSubscription

        running: true
        command: ["/usr/bin/pactl", "subscribe"]
        environment: ({ "LC_ALL": "C" })

        stdout: SplitParser {
            onRead: data => root.handleSystemStateEvent(data)
        }

        stderr: SplitParser {}

        onExited: (exitCode, exitStatus) => {
            systemStateSubscriptionRestart.restart()
        }
    }

    Process {
        id: systemStateQuery

        command: [
            "/usr/bin/wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SINK@"
        ]
        environment: ({ "LC_ALL": "C" })

        stdout: StdioCollector {
            onStreamFinished: root.applySystemState(text)
        }

        stderr: SplitParser {}

        onExited: (exitCode, exitStatus) => {
            if (!root.systemStateRefreshQueued)
                return

            root.systemStateRefreshQueued = false
            Qt.callLater(root.refreshSystemState)
        }
    }

    Timer {
        id: systemStateRefreshTimer

        interval: 25
        repeat: false
        onTriggered: root.refreshSystemState()
    }

    Timer {
        id: systemStateSubscriptionRestart

        interval: 1000
        repeat: false
        onTriggered: systemStateSubscription.running = true
    }

    onPlaybackStreamsChanged: reconcileApplicationStreams()
    Component.onCompleted: {
        reconcileApplicationStreams()
        scheduleSystemStateRefresh()
    }
}
