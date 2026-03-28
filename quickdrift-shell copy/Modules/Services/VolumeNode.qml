import QtQuick
import QtQml

import Quickshell
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Services

Scope {
    id: root

    signal ready()
    property bool isReady: false
    signal volumeChanged(int newVolume)
    property bool controllerChanging: false

    required property PwNode volumeNode
    property bool isDefault: VolumeBroker?.defaultAudioSink?.id  == volumeNode.id  ?? false
    property bool isDefaultIn: VolumeBroker?.defaultAudioSource?.id  == volumeNode.id  ?? false
    property bool isMuted: volumeNode?.audio?.muted ?? true
    property int initialVolume: -1
    property int volumePercent: 0
    property bool volumeChangeCooldown: false

    PwObjectTracker {
        id: tracker
        objects: [root.volumeNode]
    }

    Connections {
        target: root.volumeNode && root.volumeNode.audio ? root.volumeNode.audio : null
        function onVolumeChanged() {
            root.syncFromNode();
        }
    }

    onVolumeNodeChanged: {
        root.initialVolume = -1;
        root.isReady = false;
        tracker.objects = [root.volumeNode]
        if (!root.volumeNode)
            return;

        root.syncFromNode(true);
    }

    onIsMutedChanged: {
        GlobalStates.systemVolumeMuted = root.isMuted;
    }

    function syncFromNode(forceUpdate = false) {

        if (!root.volumeNode || !root.volumeNode.audio)
            return;

        const rawVolume = root.volumeNode.audio.volume;
        
        if (typeof rawVolume !== "number" || isNaN(rawVolume))
            return;

        const percent = Math.round(rawVolume * 100);

        if (root.initialVolume < 0) {
            root.initialVolume = percent;
        }
        

        if (!root.isReady) {
            root.isReady = true;
            root.ready();
        }

        if (root.isDefault) {
            GlobalStates.systemVolume = percent;
        }

        if (root.controllerChanging && !forceUpdate)
            return;

        if (root.volumePercent !== percent) {
            root.volumePercent = percent;
            root.volumeChanged(percent);
        } else if (forceUpdate) {
            root.volumeChanged(percent);
        }
    }

    function setVolume(newVolume) {
        if (!root.volumeNode || !root.volumeNode.audio)
            return;

        root.volumeNode.audio.volume = newVolume / 100;

        if (root.controllerChanging) {
            if (root.isDefault) {
                GlobalStates.systemVolume = newVolume;
            }

            if (root.volumePercent !== newVolume) {
                root.volumePercent = newVolume;
                root.volumeChanged(newVolume);
            } else {
                root.volumeChanged(newVolume);
            }
        }
    }

    function muteVolume() {
        if (volumeNode) {
            root.volumeNode.audio.muted = !root.isMuted;
        }
    }

    onVolumeChanged: {
        if(root.isDefault)
        playVolumeChangeSound()
    }

    function playVolumeChangeSound() {
        if (Settings.system.volumeSettings.volumeChangedAudioResponse && !root.volumeChangeCooldown) {
            root.volumeChangeCooldown = true;
            volumeChangeCooldownTimer.running = true;
            AudioPlayback.play(ThemeSettings.systemAudioVolumeChange);
        }
    }
    
    Timer {
        id: volumeChangeCooldownTimer
        interval: 100
        repeat: false
        running: false
        onTriggered: {
            root.volumeChangeCooldown = false;
        }
    }
}