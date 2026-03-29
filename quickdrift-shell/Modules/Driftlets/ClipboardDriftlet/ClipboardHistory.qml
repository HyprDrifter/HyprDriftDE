import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property ListModel clipboardData: clipModel

    ListModel {
        id: clipModel
    }

    property bool loaded: false

    function refresh() {
        listProcess.running = true;
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                clipModel.clear();

                for (let i = 0; i < Math.min(lines.length, 100); i++) {
                    const parts = lines[i].split("\t");
                    if (!parts[0]) continue;
                    const clipId = parts[0];
                    const summary = (parts[1] || "[[ empty ]]").slice(0, 80);
                    clipModel.append({
                        clipId: clipId,
                        summary: summary
                    });
                }

                root.loaded = true;
            }
        }
    }

    function copy(clipId) {
        Hyprland.dispatch(`exec cliphist decode ${clipId} | wl-copy`)
    }

    Timer {
        id: pollClipboard
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh()
        }
    }
}
