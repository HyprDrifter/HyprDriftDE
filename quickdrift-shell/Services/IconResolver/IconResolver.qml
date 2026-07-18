import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick.Controls
import qs.Internal
import qs.Services
import qs.Services.IconResolver
import qs.Modules.Interactive

Scope {
    id: root
    property var pendingFallbackItem: null
    property int targetIconSize: Settings.taskbarTrayIconPreferedWidth

    function setOverride(item, icon) {
        if (!item || !item.id)
            return

        if (IconOverrideStore.overrides[item.id] !== icon) {
            IconOverrideStore.overrides[item.id] = icon
            IconOverrideStore.overrideChanged(item.id)
        }
    }

    function closestIconPath(output) {
        const paths = output.split("\0").filter(path => path !== "").sort()
        let bestPath = ""
        let bestDifference = Number.POSITIVE_INFINITY

        for (const path of paths) {
            const filename = path.slice(path.lastIndexOf("/") + 1)
            if (!/\.(png|svg|ico)$/i.test(filename))
                continue

            const sizeMatch = filename.match(/([0-9]+)/)
            if (!sizeMatch)
                continue

            const size = Number(sizeMatch[1])
            if (!Number.isFinite(size))
                continue

            const difference = Math.abs(size - targetIconSize)
            if (difference < bestDifference) {
                bestDifference = difference
                bestPath = path
            }
        }

        return bestPath
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (fallbackFixer.running || root.pendingFallbackItem)
                return

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
                        root.setOverride(currentItem, "image://icon/fallback")
                        break
                    }

                    let basePath = ""
                    try {
                        basePath = decodeURIComponent(match[1])
                    } catch (error) {
                        console.warn("Invalid tray icon path:", match[1])
                        root.setOverride(currentItem, "image://icon/fallback")
                        break
                    }

                    pendingFallbackItem = currentItem;
                    fallbackFixer.command = [
                        "find", "--", basePath,
                        "-maxdepth", "1",
                        "-type", "f",
                        "(", "-iname", "*.png", "-o", "-iname", "*.svg", "-o", "-iname", "*.ico", ")",
                        "-print0"
                    ];
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
                const item = root.pendingFallbackItem
                root.pendingFallbackItem = null

                if (!item) {
                    console.warn(">>> [IconResolver] WARNING: pendingFallbackItem is null during fallback resolution!");
                    return;
                }

                const path = root.closestIconPath(this.text)
                const icon = path === "" ? "image://icon/fallback" : Qt.resolvedUrl(path).toString()
                root.setOverride(item, icon)
            }
        }
    }

}
