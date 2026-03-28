import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.Configs
import qs.Modules.Driftlets.MinimizeDriftlet

// Global Shortcuts
Scope {

    GlobalShortcut {
        name: "toggleLauncher"
        description: "Toggle App Launcher"

        onPressed: {
            GlobalStates.launcherOpen = !GlobalStates.launcherOpen
        }
    }

    GlobalShortcut {
        name: "toggleMinimizeManager"
        description: "Toggle Minimize Manager"

        onPressed: {
            GlobalStates.minimizeManagerVisible = !GlobalStates.minimizeManagerVisible
        }
    }

    GlobalShortcut {
        name: "minimizeFocusedWindow"
        description: "Minimize Active Window"

        onPressed: {
            MinimizeManager.minimizeFocusedWindow();
        }
    }

}
