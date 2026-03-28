import QtQuick
import QtQml
import QtQml.Models

// import qs.Modules
import qs.Modules.Driftlets
import qs.Modules.Driftlets.ControlPanel
import qs.Modules.Driftlets.SettingsMenu
import qs.Modules.Driftlets.SingleWidgets
import qs.Modules.Driftlets.StartMenu
import qs.Modules.Driftlets.SystemTrayDriftlet
import qs.Modules.Utilities

DelegateChooser {
    id: chooser
    role: "driftlet"

    DelegateChoice { roleValue: "ControlPanelButton"; delegate: Component { ControlPanelButton { } } }
    DelegateChoice { roleValue: "DateTimeDriftlet"; delegate: Component { DateTimeDriftlet { }} }
    DelegateChoice { roleValue: "StartButton"; delegate: Component {StartButton { } }} 
    DelegateChoice { roleValue: "SystemTrayObject"; delegate: Component {SystemTrayObject { } }} 
    DelegateChoice { roleValue: "VolumeButton"; delegate:  VolumeControls.volumeButton }
}