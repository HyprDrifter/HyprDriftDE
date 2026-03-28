pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls as Controls
import qs.Modules.Driftlets as Driftlets
import qs.Modules.Driftlets.VolumeControls
import qs.Modules.Services

Controls.Buttons.ButtonDefault {
    id: root

    readonly property int currentVolume: GlobalStates.systemVolume
    property bool isMuted: mixer.isMuted

    implicitHeight: parent.implicitHeight
    implicitWidth: implicitHeight
    background: Rectangle {
        anchors.fill: parent
        color: root.hovered ? ThemeSettings.buttons.backgroundColorHovered : "transparent"

        Text {
            id: buttonIcon
            anchors.centerIn: parent
            Layout.preferredHeight: parent.implicitHeight
            color: ThemeSettings.fontColor
            text: ThemeSettings.soundSettings.volumeMidIcon
            font.pixelSize: Settings.taskbar.geometry.height * .66
        }
    }

    VolumeMixer {
        id: mixer
        parent: root
        visible: false
    }

    onIsMutedChanged: {
        if(root.isMuted)
        {
            buttonIcon.text = ThemeSettings.soundSettings.volumeMutedIcon;
        }
        else
        {
            root.currentVolumeChanged()
        }
    }

    onCurrentVolumeChanged: {
        
        switch (true) {
        case root.currentVolume >= 80:
            buttonIcon.text = ThemeSettings.soundSettings.volumeHighIcon;
            break;
        case root.currentVolume >= 40:
            buttonIcon.text = ThemeSettings.soundSettings.volumeLowIcon;
            break;
        case root.currentVolume <= 10:
            buttonIcon.text = ThemeSettings.soundSettings.volumeOffIcon;
            break;
        }
    }

    onClicked: {
        mixer.open()
    }
}
