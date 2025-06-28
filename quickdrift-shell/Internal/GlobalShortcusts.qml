import Quickshell
import Quickshell.Hyprland
import QtQuick
import "root:/Modules"
import "root:/Modules/Interactive"
import "root:/Modules/Interactive/ApplicationLauncher"
import "root:/Services"
import "root:/Panels/MinimizeManager"



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