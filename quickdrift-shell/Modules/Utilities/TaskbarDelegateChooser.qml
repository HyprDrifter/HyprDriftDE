import QtQuick
import QtQml
import QtQml.Models

import qs.Modules.Driftlets
import qs.Modules.Driftlets.ControlPanel
import qs.Modules.Driftlets.SettingsMenu
import qs.Modules.Driftlets.SingleWidgets
import qs.Modules.Driftlets.StartMenu
import qs.Modules.Driftlets.SystemTrayDriftlet
import qs.Modules.Driftlets.WorkspaceDriftlet
import qs.Modules.Utilities

DelegateChooser {
    id: chooser
    role: "driftlet"

    DelegateChoice { roleValue: "ControlPanelButton"; delegate: Component { ControlPanelButton { } } }
    DelegateChoice { roleValue: "DateTimeDriftlet"; delegate: Component { DateTimeDriftlet { } } }
    DelegateChoice { roleValue: "StartButton"; delegate: Component { StartButton { } } }
    DelegateChoice { roleValue: "SystemTrayObject"; delegate: Component { SystemTrayObject { } } }
    DelegateChoice { roleValue: "VolumeButton"; delegate: VolumeControls.volumeButton }
    DelegateChoice { roleValue: "CpuDriftlet"; delegate: Component { CpuDriftlet { } } }
    DelegateChoice { roleValue: "GpuDriftlet"; delegate: Component { GpuDriftlet { } } }
    DelegateChoice { roleValue: "RamDriftlet"; delegate: Component { RamDriftlet { } } }
    DelegateChoice { roleValue: "ActiveWindowDriftlet"; delegate: Component { ActiveWindowDriftlet { } } }
    DelegateChoice { roleValue: "NetworkDriftlet"; delegate: Component { NetworkDriftlet { } } }
    DelegateChoice { roleValue: "BluetoothDriftlet"; delegate: Component { BluetoothDriftlet { } } }
    DelegateChoice { roleValue: "PowerDriftlet"; delegate: Component { PowerDriftlet { } } }
    DelegateChoice { roleValue: "WorkspaceManager"; delegate: Component { WorkspaceManager { } } }
    DelegateChoice { roleValue: "Spacer"; delegate: Component { Spacer { } } }
}