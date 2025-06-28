// Theme.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "root:/Internal/Themes"
import "root:/Internal"

Singleton {
    id: root

    property string loadedThemeName: ""

    function loadTheme(name) {
        loadedThemeName = name
        parser.themeName = name  // Store it here for later use
        parser.command = [
            "yq", "eval", "-o=json",
            Qt.resolvedUrl("./base16/" + name + ".yaml").toString().replace("file://", "")
        ]
        console.log("after set command")
        parser.running = true
    }

    function hexToRGB(hex, alpha) {
        const r = parseInt(hex.toString().slice(1, 3), 16) / 255;
        const g = parseInt(hex.toString().slice(3, 5), 16) / 255;
        const b = parseInt(hex.toString().slice(5, 7), 16) / 255;
        const a = (alpha !== undefined) ? alpha : 1;

        return Qt.rgba(r, g, b, a);
    }

    Process {
        id: parser
        property string themeName: ""  // Carry name into callback
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    console.log("Before parse")
                    const parsed = JSON.parse(this.text)
                    console.log(parsed)
                    if (parsed.palette) {
                        console.log("✅ Loaded base16 theme:", parser.themeName)
                        Settings.applyThemeFromMap(parsed.palette)
                    } else {
                        console.warn("⚠️ Theme file missing 'palette' section")
                    }
                } catch (e) {
                    console.error("❌ Theme parse error:", e)
                    console.error("Raw text from parser:", this.text)
                }
            }
        }
    }
}
