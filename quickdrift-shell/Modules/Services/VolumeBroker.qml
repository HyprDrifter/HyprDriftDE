pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQml.Models

import Quickshell
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Modules.Services

Singleton {
    id: root

    signal loading
    signal ready
    property bool isReady: false

    readonly property bool pipewireReady: Pipewire.ready

    property int systemVolume: defaultAudioSink?.audio?.volume * 100 ?? 0
    property PwNode defaultAudioSource: Pipewire.defaultAudioSource
    property PwNode defaultAudioSink: Pipewire.defaultAudioSink
    property VolumeNode defaultAudioOut
    property list<PwNode> pipewireNodes: Pipewire.nodes.values
    property list<PwNode> currentNodes

    property int initMaxVolume: Settings.system.volumeSettings.maxVolume
    property bool raiseMaxVolume: Settings.system.volumeSettings.raiseMaxVolume
    property int maxVolumeIncrease: Settings.system.volumeSettings.maxVolumeIncrease
    property int maxVolume: raiseMaxVolume ? initMaxVolume + maxVolumeIncrease : initMaxVolume

    property list<PwNode> audioOutputNodes: pipewireNodes.filter(n => n.isSink)
    property list<PwNode> audioInputNodes: pipewireNodes.filter(n => n.audio)
    property list<PwNode> audioStreams: pipewireNodes.filter(n => n.isStream && !n.isSink)

    property list<VolumeNode> outputs: [
        VolumeNode {volumeNode:root.defaultAudioSink; isDefault:true}
    ]
    property list<VolumeNode> inputs: [
        VolumeNode {volumeNode:root.defaultAudioSource; isDefaultIn:true}
    ]
    property list<VolumeNode> applications: []

    
    onOutputsChanged: updateDefault()
    function updateDefault() {
        if(outputs)
        {
            root.defaultAudioOut = outputs.find(o => o.isDefault == true) ?? undefined
        }
        if(inputs)
        {
            root.defaultAudioOut = outputs.find(o => o.isDefault == true) ?? undefined
        }
    }

    onLoading: {
        if (pipewireReady) {
            Logger.logWithHeader(["VolumeBroker is ready"]);

            for (let n in root.pipewireNodes)
            { Logger.log([`- Node: ${pipewireNodes[n].name} (ID: ${pipewireNodes[n].id})`]) }
            ready()
        }
    }

    onReady: {
        updateDefault()
        root.isReady = true
    }

    //onPipewireNodesChanged: {console.log(`${root.pipewireNodes.length}`)}
    
    onDefaultAudioOutChanged: {
        if(root.defaultAudioOut) {
            Logger.logWithHeader([
            `New default audio out`,
            `${root.defaultAudioOut?.volumeNode?.name}`
            ])
        }
    }


    function activate() {
        loading();
    }
}
