import QtQuick

import Quickshell.Io

import qs.Configs
import qs.Configs.Settings

JsonObject {
    id: root

    property bool taskbarsSynced: true
    property bool taskbarSingle: false

    property list<var> taskbarMembersLeft: [
        {
            driftlet: "StartButton",
            enabled: true,
        },
    ]

    property list<var> taskbarMembersCenter: [
        
    ]

    property list<var> taskbarMembersRight: [
        {
            driftlet:"DateTimeDriftlet",
            enabled: true,
        },
        {
            driftlet:"ControlPanelButton",
            enabled: true,
        }
    ]
    
    property JsonObject margins: JsonObject {
        property int padFloat: 5
        property int padLong: 15
        property int popupGap: 5
        property int top: (root.anchors.floating && root.anchors.anchorTop ? padFloat : 0) + (root.anchors.anchorLongWays && root.anchors.vertical ? padLong : 0)
        property int bottom: (root.anchors.floating && root.anchors.anchorBottom ? padFloat : 0) + (root.anchors.anchorLongWays && root.anchors.vertical ? padLong : 0)
        property int left: (root.anchors.floating && root.anchors.anchorLeft ? padFloat : 0) + (root.anchors.anchorLongWays && !root.anchors.vertical ? padLong : 0)
        property int right: (root.anchors.floating && root.anchors.anchorRight ? padFloat : 0) + (root.anchors.anchorLongWays && !root.anchors.vertical ? padLong : 0)
    }

    property JsonObject geometry: JsonObject {
        property int height: root.anchors.vertical ? 800 : 40
        property int width: root.anchors.vertical ? 40 : 1800
        property int radius: 12
    }

    property JsonObject anchors: JsonObject {

        property bool vertical: anchorLeft || anchorRight ? true : false
        property bool anchorLongWays : true
        property bool anchorCenter : true
        property bool anchorTop : false
        property bool anchorLeft : false
        property bool anchorRight : false
        property bool anchorBottom : true
        property bool floating : true
        property bool above : true
    }

    function setHeight(height) {
        root.geometry.height = height
    }

}