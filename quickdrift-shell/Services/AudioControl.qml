pragma Singleton
pragma ComponentBehavior: Bound
import "root:/Internal"
import "root:/Services"
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property int currentVolume: Math.round(sink.audio.volume * 100)
    property bool audioOnCooldown: false

    signal sinkProtectionTriggered(string reason)

    PwObjectTracker {
        objects: [sink, source]
    }

    Connections {

        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {

            if (!Settings.audioProtection)
                return;
            if (!lastReady) {
                lastVolume = sink.audio.volume;
                lastReady = true;
                return;
            }
            const newVolume = sink.audio.volume;
            const maxAllowedIncrease = Settings.audioMaxIncrease / 100;
            const maxAllowed = Settings.audioMaxVolume / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered("Illegal increment");
            } else if (newVolume <= 0) {
                if (!sink.ready) {return;}
                sink.audio.volume = 0;
                root.sinkProtectionTriggered("Exceeded max allowed");
            } else if (newVolume > maxAllowed) {
                if (!sink.ready) {return;}
                sink.audio.volume = maxAllowed;
                root.sinkProtectionTriggered("Exceeded max allowed");
            } 
            if(!root.audioOnCooldown)
            {
                AudioPlayback.play(Settings.systemAudioVolumeChange)
                root.audioOnCooldown = true
                audioCooldownTimer.running = true
            }
            lastVolume = Math.round(sink.audio.volume * 100) / 100;
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
}
