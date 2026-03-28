import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQml.Models
import qs.Modules.Driftlets.ClipboardDriftlet

Singleton {
    id: root

    property JsonAdapter entries: JsonAdapter {
        id: clipdata
        property var data: []
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
                const jsonList = [];

                lines.forEach((line, i) => {
                    const id = (line.split("\t")[0] || "[[ empty ]]");
                    const summary = (line.split("\t")[1] || "[[ empty ]]").slice(0, 80);
                    jsonList.push({
                        id: id,
                        summary: summary
                    });
                });

                clipdata.data = jsonList;
                root.loaded = true;
            }
        }
    }

    function copy(id) {
        console.log(`Copying clipboard entry: ${id.toString()}`)
        Hyprland.dispatch(`exec cliphist decode ${id.toString()} | wl-copy`)
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
