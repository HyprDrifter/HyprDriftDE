import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Controls
import qs.Services
import qs.Services.IconResolver
import qs.Modules.Interactive

Scope {
    id: root
    property var pendingFallbackItem: null
    property string pendingFallbackPath: ""
    property int pendingFallbackIndex: undefined

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var itemList = SystemTray.items.values;

            ////console.lgo("~~~~~ : " + itemList.length)


            for (var i = 0; i < SystemTray.items.values.length; i++) {
                var currentItem = itemList[i];
                var currentIcon = currentItem.icon;

                if (
                    currentItem.status === 0 &&
                    currentIcon &&
                    currentIcon.includes("path=") &&
                    IconOverrideStore.overrides[currentItem.id] === undefined
                ) {
                    console.warn("Broken tray icon detected:", currentItem.title, currentItem.icon);

                    //console.lgo("-----------------------------------------------------");
                    //console.lgo("Array position : " + i);
                    //console.lgo("Status:", currentItem.status);
                    //console.lgo("Icon source:", currentItem.icon);
                    //console.lgo("Item ID:", currentItem.id);
                    //console.lgo("Title:", currentItem.title);
                    //console.lgo("Tooltip:", currentItem.tooltipDescription);

                    const match = currentIcon.match(/path=([^&]+)/);
                    if (!match || !match[1]) {
                        currentIcon = "image://icon/fallback";
                        continue;
                    }

                    const basePath = decodeURIComponent(match[1]);
                    const filenameMatch = currentIcon.match(/icon\/([^?]+)/);
                    const basename = filenameMatch ? filenameMatch[1] : "fallback";

                    const fsCommand = `
                        cd "${basePath}" && \
                        ls | grep -E '\\.(png|svg|ico)$' | grep -E '[0-9]+' | awk '
                        BEGIN { target = ${root.trayItemWidth || 24}; minDiff = 99999 }
                        {
                            match($0, /([0-9]+)/, m);
                            diff = (m[1] - target >= 0) ? m[1] - target : target - m[1];
                            if (diff < minDiff) {
                                minDiff = diff;
                                best = $0;
                            }
                        }
                        END { print best }'
                    `;

                    pendingFallbackItem = currentItem;
                    pendingFallbackPath = basePath;
                    pendingFallbackIndex = i;
                    //console.lgo(">>> [IconResolver] Executing fallback scan command:\n" + fsCommand);
                    fallbackFixer.command = ["bash", "-c", fsCommand];
                    fallbackFixer.running = true;

                    break; // only one item per cycle
                }

            }
        }
    }

    Process {
        id: fallbackFixer
        stdout: StdioCollector {
            onStreamFinished: {
                const filename = this.text.trim();
                //console.lgo(">>> [IconResolver] Fallback resolution finished");

                if (!pendingFallbackItem) {
                    console.warn(">>> [IconResolver] WARNING: pendingFallbackItem is null during fallback resolution!");
                    return;
                }

                const id = pendingFallbackItem.id;
                const originalIcon = pendingFallbackItem.icon;
                let resolvedPath = "";

                if (filename !== "" && pendingFallbackItem) {
                    const newPath = "file://" + pendingFallbackPath + "/" + filename;

                    if (IconOverrideStore.overrides[pendingFallbackItem.id] !== newPath) {
                        IconOverrideStore.overrides[pendingFallbackItem.id] = newPath;
                        IconOverrideStore.overrideChanged(pendingFallbackItem.id);
                    } else {
                        //console.lgo(">>> [IconResolver] Skipping duplicate override assignment for:", pendingFallbackItem.id);
                    }
                } else if (pendingFallbackItem) {
                    const fallback = "image://icon/fallback";

                    if (IconOverrideStore.overrides[pendingFallbackItem.id] !== fallback) {
                        IconOverrideStore.overrides[pendingFallbackItem.id] = fallback;
                        IconOverrideStore.overrideChanged(pendingFallbackItem.id);
                    } else {
                        //console.lgo(">>> [IconResolver] Skipping duplicate fallback assignment for:", pendingFallbackItem.id);
                    }
                }

                // Confirm the update was stored
                //console.lgo(`>>> [IconResolver] Confirm override store: IconOverrideStore.overrides["${id}"] = ${IconOverrideStore.overrides[id]}`);
                //console.lgo(">>> [IconResolver] Original system icon: " + originalIcon);

            }
        }
    }

}
