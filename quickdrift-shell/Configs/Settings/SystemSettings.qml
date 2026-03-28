import QtQuick
import QtQml

import Quickshell
import Quickshell.Io

import qs.Configs

JsonObject {

    property JsonObject volumeState: JsonObject {
        property int systemVolume: 100

        property list<string> outputDevices: []

        property list<string> inputDevices: []
    }
    
    property JsonObject volumeSettings: JsonObject {
        
        readonly property int maxVolume: 100
        property bool raiseMaxVolume: true
        property int maxVolumeIncrease: 50
        property int volumeStep: 1
        property bool volumeChangedAudioResponse: true
    }

    property JsonObject logSettings: JsonObject {
        property int logLevel: 0
        property string logPath: `${GlobalStates.userDirectory}/.cache/hyprdrift/quickdrift`
    }
}