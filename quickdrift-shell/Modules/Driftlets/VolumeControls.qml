pragma Singleton
import QtQuick
import QtQml

import Quickshell

import qs.Modules.Driftlets.VolumeControls as VControls

Singleton {
    id: root

    component VolumeButton: VControls.VolumeButton { }
    property Component volumeButton: Component { VControls.VolumeButton { } }

    component VolumeController: VControls.VolumeController { }
    property Component volumeController: Component { VControls.VolumeController { } }

    component VolumeMixer: VControls.VolumeMixer { }
    property Component volumeMixer: Component { VControls.VolumeMixer { } }
    

}