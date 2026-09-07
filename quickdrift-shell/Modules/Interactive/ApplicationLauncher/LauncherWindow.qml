pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

PanelWindow {
    id: root

    visible: GlobalVariables.launcherOpen
    implicitWidth: Hyprland.focusedMonitor.width
        * Settings.applaunchWidthInScreenPercent
    implicitHeight: Hyprland.focusedMonitor.height
        * Settings.applaunchHeightInScreenPercent
    color: "transparent"

    property string filterText: ""

    readonly property string rawInput: searchField.text.trim()
    readonly property bool commandMode: rawInput.startsWith(">")
    readonly property string typedCommand: commandMode
        ? rawInput.slice(1).trim()
        : rawInput
    readonly property var filteredApps: commandMode
        ? []
        : ApplicationIndex.results(filterText)
    readonly property bool showCommandRow: commandMode
        || (typedCommand.length > 0 && filteredApps.length === 0)
    readonly property var commandRow: ({
        modelKey: "command:" + typedCommand,
        command: true,
        available: typedCommand.length > 0,
        id: "",
        name: "Run command",
        description: typedCommand,
        icon: "utilities-terminal"
    })
    readonly property var displayRows: showCommandRow
        ? [commandRow]
        : filteredApps

    function flushSearch(): void {
        searchDebounce.stop()
        filterText = searchField.text
    }

    function launchDesktopRecord(record): bool {
        return ApplicationLaunchService.launchDesktopId(record?.id || "")
    }

    function launchCommand(): bool {
        if (typedCommand.length === 0)
            return false
        return ApplicationLaunchService.launchShellCommand(typedCommand)
    }

    function launchRow(row): bool {
        if (!row)
            return false
        return row.command === true
            ? launchCommand()
            : launchDesktopRecord(row)
    }

    function launchCurrentSelection(forceCommand): void {
        flushSearch()

        if (forceCommand) {
            launchCommand()
        } else if (displayRows.length > 0) {
            const selectedIndex = Math.max(0,
                Math.min(appList.currentIndex, displayRows.length - 1))
            launchRow(displayRows[selectedIndex])
        } else if (typedCommand.length > 0) {
            launchCommand()
        }

        GlobalVariables.launcherOpen = false
    }

    function handleLauncherKey(event): void {
        if (event.key === Qt.Key_Escape) {
            GlobalVariables.launcherOpen = false
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            launchCurrentSelection(
                (event.modifiers & Qt.ControlModifier) !== 0)
            event.accepted = true
            return
        }

        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down)
                && appList.count > 0) {
            if (event.key === Qt.Key_Up) {
                appList.currentIndex = appList.currentIndex <= 0
                    ? appList.count - 1
                    : appList.currentIndex - 1
            } else {
                appList.currentIndex = appList.currentIndex
                        >= appList.count - 1
                    ? 0
                    : appList.currentIndex + 1
            }
            event.accepted = true
        }
    }

    onDisplayRowsChanged: {
        appList.currentIndex = displayRows.length > 0 ? 0 : -1
    }

    onVisibleChanged: {
        if (visible) {
            grab.active = true

            // Give layout time to settle before taking keyboard focus.
            Qt.callLater(() => {
                searchField.forceActiveFocus()
                appList.currentIndex = appList.count > 0 ? 0 : -1
            })
        } else if (Settings.applaunchClearTextOnClose) {
            searchDebounce.stop()
            searchField.text = ""
            filterText = ""
        }
    }

    Timer {
        id: searchDebounce
        interval: Settings.applaunchSearchDebounceMs
        repeat: false
        onTriggered: root.filterText = searchField.text
    }

    ScriptModel {
        id: launcherModel
        objectProp: "modelKey"
        values: root.displayRows
    }

    HyprlandFocusGrab {
        id: grab
        windows: [root]

        onCleared: GlobalVariables.launcherOpen = false
    }

    Rectangle {
        id: layoutHoldingRect
        anchors.fill: parent
        color: Settings.applaunchLauncherColor
        radius: 16

        Keys.onPressed: event => root.handleLauncherKey(event)

        ColumnLayout {
            id: launcherLayout
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 10

            TextField {
                id: searchField

                Layout.preferredWidth: launcherLayout.width * 0.9
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                implicitHeight: 36
                placeholderText: "Search applications or enter a command…"
                selectByMouse: true
                onTextChanged: searchDebounce.restart()
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleLauncherKey(event)
                horizontalAlignment: Settings.applaunchTextInputAlignment === 1
                    ? TextInput.AlignLeft
                    : Settings.applaunchTextInputAlignment === 2
                        ? TextInput.AlignHCenter
                        : TextInput.AlignRight

                background: Rectangle {
                    color: Settings.applaunchSearchBarColor
                    radius: 6
                }
                color: Settings.applaunchSearchBarTextColor
            }

            ListView {
                id: appList

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 5
                Layout.bottomMargin: 15
                model: launcherModel
                spacing: 4
                clip: true
                highlightFollowsCurrentItem: true
                focus: true
                keyNavigationEnabled: true
                keyNavigationWraps: true

                ScrollIndicator.vertical: ScrollIndicator {
                    active: true
                }

                delegate: Button {
                    id: appToLaunch

                    required property int index
                    required property var modelData

                    readonly property var rowData: modelData
                    readonly property bool isCommand: rowData.command === true

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: appList.width * 0.9
                    height: Settings.applaunchRowHeight
                    enabled: rowData.available === true
                    focusPolicy: Qt.NoFocus

                    onClicked: {
                        root.launchRow(rowData)
                        GlobalVariables.launcherOpen = false
                    }
                    onHoveredChanged: {
                        if (hovered)
                            appList.currentIndex = index
                    }

                    background: Rectangle {
                        color: appToLaunch.ListView.isCurrentItem
                            ? Settings.applaunchSearchBarColor
                            : "transparent"
                        radius: 6
                    }

                    contentItem: RowLayout {
                        spacing: 10

                        Item {
                            Layout.preferredWidth: Settings.applaunchIconSize
                            Layout.preferredHeight: Settings.applaunchIconSize

                            IconImage {
                                id: applicationIcon
                                anchors.fill: parent
                                source: appToLaunch.isCommand
                                    ? Quickshell.iconPath(
                                        "utilities-terminal",
                                        "application-x-executable")
                                    : ApplicationIndex.iconSource(
                                        appToLaunch.rowData)
                                asynchronous: true
                                mipmap: true
                                opacity: status === Image.Error ? 0 : 1
                            }

                            IconImage {
                                anchors.fill: parent
                                source: Quickshell.iconPath(
                                    "application-x-executable")
                                asynchronous: true
                                mipmap: true
                                visible: applicationIcon.status === Image.Error
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: appToLaunch.rowData.name
                                color: Settings.text
                                font.family: Settings.fontFamily
                                font.pixelSize: Settings.fontPixelSize
                                font.bold: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: appToLaunch.rowData.description || ""
                                color: Settings.rosewater
                                font.family: Settings.fontFamily
                                font.pixelSize: Math.max(10,
                                    Settings.fontPixelSize - 2)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                visible: text.length > 0
                            }
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Visible)
                }
            }
        }
    }
}
