import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    property string filterText: ""
    readonly property var filteredApps: {
        const query = filterText.trim().toLowerCase();
        const applications = DesktopEntries.applications.values;

        if (query === "")
            return applications;

        return applications.filter(entry => entry.name && entry.name.toLowerCase().includes(query));
    }

    function launchCurrentSelection() {
        const input = searchField.text.trim();

        if (filteredApps.length > 0) {
            const selectedIndex = Math.max(0, Math.min(appList.currentIndex, filteredApps.length - 1));
            filteredApps[selectedIndex].execute();
        } else if (input !== "") {
            Quickshell.execDetached(["bash", "-lc", input]);
        }

        GlobalVariables.launcherOpen = false;
    }

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
                root.launchCurrentSelection();
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
                onTextChanged: {
                    filterText = text
                    appList.currentIndex = 0
                }
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
                        property var desktopEntry: modelData
                        property string appName: modelData.name

                        onClicked: {
                            desktopEntry.execute();
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
