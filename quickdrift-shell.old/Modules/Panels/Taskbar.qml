import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import QtQuick.Controls
import Quickshell.Widgets
import qs.Internal
import qs.Modules.Performance
import qs.Modules.Interactive
import qs.Modules.Interactive.ClipboardManager
import qs.Modules.Interactive.ApplicationLauncher
import qs.Modules.Interactive.VolumeController
import qs.Modules.Utility


Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: taskbarRoot

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 20
            implicitWidth: 100

            RowLayout{
                id: mainRowLayout

                RowLayout {
                    id: leftRowLayout
                }

                RowLayout {
                    id: centerRowLayout
                }

                RowLayout {
                    id: rightRowLayout
                }
            }
        }
    }
}
