import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Modules.Interactive
import qs.Modules.Interactive.ApplicationLauncher
import qs.Internal
import qs.Services

PanelWindow {
    id: root
    visible: GlobalVariables.launcherOpen
    implicitWidth: Hyprland.focusedMonitor.width * Settings.applaunchWidthInScreenPercent
    implicitHeight: Hyprland.focusedMonitor.height * Settings.applaunchHeightInScreenPercent
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            grab.active = true;

            //Give time for layout/rendering to complete before requesting focus
            Qt.callLater(() => {
                searchField.forceActiveFocus();
                appList.currentIndex = 0
            });
        }
        if (!visible) {
            if (Settings.applaunchClearTextOnClose) {
                searchField.text = "";
            }
        }
    }

    HyprlandFocusGrab {
        id: grab
        windows: [root]

        onCleared: {
            GlobalVariables.launcherOpen = false;
        }
    }

    FileView {
        id: appFile
        path: "/tmp/hyprdrift/apps.json"
        watchChanges: true

        onFileChanged: {
            console.log("apps.json changed, reloading and refreshing");
            reload();              // reload JsonAdapter
            refreshAppList.running = true; // re-run Get-Apps.sh
        }

        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: appData
            property var apps: []
        }
    }

    Process {
        id: refreshAppList
        // Convert file:// to absolute path
        command: ["/bin/bash", Qt.resolvedUrl("../../../Scripts/Get-Apps.sh").toString().replace("file://", "")]
        running: true

        onStarted: console.log("!@!@!@!@!@!Refreshing apps from Get-Apps.sh")

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("Get-Apps.sh ran successfully");
            } else {
                console.warn(`Get-Apps.sh failed with code ${exitCode} and status ${exitStatus}`);
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 10000 // 10 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        //triggeredOnStart: true
        onTriggered: {
            appFile.reload();
            refreshAppList.running = true;
        }
    }

    property string filterText: ""
    property var filteredApps: {
        if (!appData.apps || appData.apps.length === 0)
            return [];

        if (!filterText || filterText.trim() === "") {
            console.log("Returning full app list");
            return appData.apps;
        }

        const result = appData.apps.filter(app => app.name && app.name.toLowerCase().includes(filterText.toLowerCase()));
        console.log("Filtered result:", JSON.stringify(result));
        return result;
    }

    Rectangle {
        id: layoutHoldingRect
        anchors.fill: parent
        color: Settings.applaunchLauncherColor
        //opacity: .85
        radius: 16

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalVariables.launcherOpen = false;
                event.accepted = true;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var app = appList.currentItem;
                if(appList.count > 0)
                {
                    Hyprland.dispatch(`exec ${app.appExec}`);
                } else if (searchField.text.trim() !== "") {
                    Hyprland.dispatch(`exec ${searchField.text}`);
                }
                GlobalVariables.launcherOpen = false;
                event.accepted = true;
            }
            if(event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            {
                switch (event.key)
                {
                    case Qt.Key_Up:
                        if(appList.currentIndex === 0)
                        {
                            appList.currentIndex = appList.count - 1
                        }
                        else {
                            appList.currentIndex--
                        }
                        break;
                    case Qt.Key_Down:
                        if(appList.currentIndex === appList.count - 1)
                        {
                            appList.currentIndex = 0
                        }
                        else {
                            appList.currentIndex++
                        }
                        break;
                }
            }
        }

        ColumnLayout {
            id: iconColumn
            anchors.fill: parent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: 4
                rightMargin: 4
            }
            implicitHeight: root.height
            implicitWidth: root.implicitWidth
            spacing: 10

            Component.onCompleted: {
                console.log("apps loaded:", JSON.stringify(appData.apps));
            }

            TextField {
                id: searchField
                Layout.preferredWidth: iconColumn.implicitWidth * .90
                Layout.alignment: Qt.AlignHCenter
                //anchors.horizontalCenter: parent.horizontalCenter
                Layout.topMargin: 10
                implicitHeight: 36
                placeholderText: "Search..."
                //focus: true
                selectByMouse: true
                onTextChanged: filterText = text
                horizontalAlignment: Settings.applaunchTextInputAlignment === 1 ? TextInput.AlignLeft : Settings.applaunchTextInputAlignment === 2 ? TextInput.AlignHCenter : TextInput.AlignRight

                background: Rectangle {
                    color: Settings.applaunchSearchBarColor
                    radius: 6
                }
                color: Settings.applaunchSearchBarTextColor
            }

            ListView {
                id: appList
                model: filteredApps
                ScrollIndicator.vertical: ScrollIndicator {
                    active: true
                }

                highlightFollowsCurrentItem: true
                focus: true

                keyNavigationEnabled: true
                keyNavigationWraps: true

                Layout.topMargin: 15
                Layout.bottomMargin: 15
                implicitHeight: root.implicitHeight - (searchField.height + Layout.topMargin + Layout.bottomMargin + 10)
                implicitWidth: root.implicitWidth
                

                spacing: 8

                delegate: 
                    Button {
                        id: appToLaunch
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitHeight: 36
                        implicitWidth: appList.implicitWidth * .75
                        property string appName: modelData.name
                        property string appExec: modelData.exec

                        onClicked: {
                            Hyprland.dispatch(`exec ${modelData.exec}`);
                            GlobalVariables.launcherOpen = false;
                        }

                        onHoveredChanged: {
                            appList.currentIndex = index
                        }

                        background: Rectangle {
                            id: backRect
                            color: appToLaunch.ListView.isCurrentItem ? Settings.applaunchSearchBarColor : "transparent"
                            radius: 6
                        }

                        StyledText {
                            id: buttonText
                            anchors.centerIn: parent
                            text: modelData.name
                        }
                    }
                


                onCurrentIndexChanged: {
                    // Only scroll if index is valid
                    if (currentIndex >= 0)
                        appList.positionViewAtIndex(currentIndex, ListView.Visible);
                }
            }

            
            
        }
    }

}
