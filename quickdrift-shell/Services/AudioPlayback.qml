pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Hyprland

Singleton {
    function play(fileLocation) {
        Hyprland.dispatch(`exec paplay ${fileLocation}`)
    }
}