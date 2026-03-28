pragma Singleton

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Modules.Services

Scope {
    id: root

    property list<PanelWindow> taskbarList: []
    
    property bool controlPanelVisible : false

    property ShellScreen activeScreen: ToplevelManager.activeToplevel?.screens[0] ?? null

    property string userName: Quickshell.env("$USER")
    property string userDirectory: Quickshell.env("$HOME")

    property int systemVolume: VolumeBroker.systemVolume
    property bool systemVolumeMuted:VolumeBroker.defaultAudioOut ? VolumeBroker.defaultAudioOut?.isMuted : true
}