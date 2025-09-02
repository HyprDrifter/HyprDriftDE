import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.Modules.Interactive
import qs.Modules.Interactive.ApplicationLauncher
import qs.Services
import qs.Panels.MinimizeManager



// Global Shortcuts
Scope{

    GlobalShortcut {
        name: "toggleLauncher"
        description: "Toggle App Launcher"

        onPressed: {
            GlobalVariables.launcherOpen = !GlobalVariables.launcherOpen
        }
    }

    GlobalShortcut {
        name: "toggleMinimizeManager"
        description: "Toggle Minimize Manager"

        onPressed: {
            GlobalVariables.minimizeManagerVisible = !GlobalVariables.minimizeManagerVisible
        }
    }

    GlobalShortcut {
        name: "minimizeFocusedWindow"
        description: "Minimize Ative Window"

        onPressed: {
            MinimizeManager.minimizeFocusedWindow();
        }
    }

}