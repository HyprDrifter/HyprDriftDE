import QtQuick
import QtQuick.Controls
import QtQml
import QtQml.Models

import Quickshell

import qs.Configs

Slider {
    id: root

    required property int min
    required property int max
    property alias current: root.value
    property alias liveDrag: root.live

    from: min
    to: max
    live: true
}