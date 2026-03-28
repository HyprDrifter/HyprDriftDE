import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property string stateFile: "/tmp/minimize-state/windows.json"
    property string previewDir: "/tmp/window-previews"
    property string selectedAddress: ""

    Process {
        id: validateFile
        command: ["bash", "-c", "test -s '" + root.stateFile + "' && jq . '" + root.stateFile + "' >/dev/null"]
        running: true
        onFinished: {
            if (exitCode !== 0) {
                Notify.send("No minimized windows or state file is corrupt");
            } else {
                listWindows.running = true;
            }
        }
    }

    Process {
        id: listWindows
        stdout: StdioCollector {
            onStreamFinished: {
                let jqCmd = `
                jq -c '.[]' "${root.stateFile}" | awk '
                {
                    cmd = "jq -r \\".address, .class, .original_title, .preview\\" <<< " $0
                    cmd | getline out
                    close(cmd)
                    split(out, a, "\n")
                    if (a[1] != "") {
                        if (a[4] != "" && system("[ -f " a[4] " ]") == 0)
                            print a[1] "|||" (a[3] != "" ? a[3] : a[2]) "\\0icon\\x1f" a[4]
                        else
                            print a[1] "|||" (a[3] != "" ? a[3] : a[2])
                    }
                }'
                `;

                rofiInput.command = ["bash", "-c", jqCmd];
                rofiInput.running = true;
            }
        }
        command: ["bash", "-c", "echo listing"]
    }

    Process {
        id: rofiInput
        stdout: StdioCollector {
            onStreamFinished: {
                let rofiCmd = `
                echo -e '${this.text}' | cut -d'|' -f4- | rofi -dmenu -theme-str 'window { width: 700px; }' -format 'i'
                `;

                rofiSelect.command = ["bash", "-c", rofiCmd];
                rofiSelect.running = true;
            }
        }
    }

    Process {
        id: rofiSelect
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "" || this.text === "-1")
                    return;

                let index = this.text.trim();
                getAddress.command = ["jq", "-r", ".[" + index + "].address", root.stateFile];
                getAddress.running = true;
            }
        }
    }

    Process {
        id: getAddress
        stdout: StdioCollector {
            onStreamFinished: {
                root.selectedAddress = this.text.trim();
                restoreWindow.command = ["/usr/local/bin/niflveil", "restore", root.selectedAddress];
                restoreWindow.running = true;
            }
        }
    }

    Process {
        id: restoreWindow
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.indexOf("Move from special workspace result:") !== -1) {
                    // Clean up
                    let cleanupCmd = `
                        jq "del(.[] | select(.address == \\"${root.selectedAddress}\\"))" '${root.stateFile}' > '${root.stateFile}.tmp' &&
                        mv '${root.stateFile}.tmp' '${root.stateFile}' &&
                        rm -f '${root.previewDir}/${root.selectedAddress}.thumb.png'
                    `;

                    cleanup.command = ["bash", "-c", cleanupCmd];
                    cleanup.running = true;
                } else {
                    Notify.send("Failed to restore window", this.text);
                }
            }
        }
    }

    Process {
        id: cleanup
        onFinished: Notify.send("Window restored successfully")
    }
}
