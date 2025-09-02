pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQml.Models
import qs.Modules.Interactive.ClipboardManager

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

                    //console.log(jsonList[i].id)
                });

                // Assign to the adapter
                clipdata.data = jsonList;
                root.loaded = true;
                //console.log("Clip list updated, count:", clipdata.data.length);
            }
        }
    }

    function copy(id) {
        console.log(`Gonna do command  "cliphist", "decode", ${id.toString()}, "|", " wl-copy"`)
        Hyprland.dispatch(`exec cliphist decode ${id.toString()} | wl-copy`)
        //decodeProc.command = ["cliphist", "decode", id.toString(), " |"," wl-copy"];
    }

    Timer {
        id: pollClipboard
        interval: 1000 // every 1s
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh()
    }
}
}
