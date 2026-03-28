pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls.Buttons
import qs.Modules.Driftlets.ControlPanel
import qs.Modules.Driftlets.StartMenu
import qs.Modules.Services

PopupWindow {
    id: root

    required property var parent
    property int taskbarGap: Settings.taskbar.margins.popupGap
    property var toggle: startMenuRect.toggle

    implicitHeight: 550
    implicitWidth: 500
    color: "transparent"
    visible: false
    anchor.item: parent
    anchor.rect.x: parent.x - parent.anchors.leftMargin
    anchor.rect.y: (root.height + parent.y + taskbarGap) * -1

    //property list<var> favorites: [{a:"1"},{a:"2"},{a:"3"},{a:"4"},{a:"5"},{a:"6"},{a:"7"},{a:"8"},{a:"9"},{a:"10"},{a:"11"},{a:"12"},]
    property list<QtObject> favorites: DesktopEntries.applications.values

    HyprlandFocusGrab {
        id:fcsGrbr
        windows: [root]
        onCleared: {startMenuRect.toggle(); searchField.clear()}
        onActiveChanged: {if(active) { searchField.focus = true}}
    }

    Rectangle {
        id: startMenuRect
        implicitWidth: root.width
        visible: root.visible
        anchors.bottom: parent.bottom
        state: "closed"
        color: ThemeSettings.clipmanPopupBackground
        radius:Settings.taskbar.geometry.radius
        property alias search: searchField

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                startMenuRect.toggle();
                event.accepted = true;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var app = programsLV.currentItem;
                if(programsLV.count > 0)
                {
                    app.execute()
                } else if (searchField.text.trim() !== "") {
                    Hyprland.dispatch(`exec ${searchField.text}`);
                    searchField.clear()
                }
                startMenuRect.toggle();
                event.accepted = true;
            }
            if(event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            {
                switch (event.key)
                {
                    case Qt.Key_Up:
                    if(programsLV.currentIndex === 0)
                    {
                        programsLV.currentIndex = programsLV.count - 1
                    }
                    else {
                        programsLV.currentIndex--
                    }
                    break;
                    case Qt.Key_Down:
                    if(programsLV.currentIndex === programsLV.count - 1)
                    {
                        programsLV.currentIndex = 0
                    }
                    else {
                        programsLV.currentIndex++
                    }
                    break;
                }
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "implicitHeight"
                duration: root.height / 1.5
                easing.type: Easing.OutQuint
            }
            onRunningChanged: {
                if (!running && startMenuRect.state == "closed" && startMenuRect.implicitHeight <= 1) {
                    root.visible = false;
                }
            }
        }
        states: [
            State {
                name: "closed"
                PropertyChanges { startMenuRect.implicitHeight: 1; fcsGrbr.active: false}
            },
            State {
                name: "opened"
                PropertyChanges {startMenuRect.implicitHeight: root.height; fcsGrbr.active: true}
            }
        ]

        RowLayout {
            anchors.fill: startMenuRect
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                top: parent.bottom
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 2
                Layout.preferredHeight: 1
                color: "transparent"

                border {
                    color: "black"
                    width: 2
                }

                ColumnLayout {
                    anchors{
                        fill: parent
                    }
                    Rectangle {
                        color: "transparent"
                        Layout.fillHeight: true;
                        Layout.fillWidth: true;
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 5
                Layout.preferredHeight: 10
                color: "transparent"
                border {
                    color: "black"
                    width: 2
                }
                ColumnLayout {

                    anchors{
                        fill: parent

                        topMargin: 10
                        bottomMargin: 10
                    }
                    spacing: 10

                    Rectangle {
                        id: searchFieldRectangle
                        Layout.preferredHeight: 30
                        implicitHeight: 30
                        Layout.preferredWidth: parent.width * .95
                        Layout.alignment: Qt.AlignHCenter

                        color: "transparent"
                        TextField {
                            id: searchField
                            anchors.fill: searchFieldRectangle
                            background: Rectangle {
                                anchors.fill: parent
                                color: ThemeSettings.applaunchSearchBarColor
                            }
                            color: ThemeSettings.applaunchSearchBarTextColor
                            onFocusChanged: {if(focus) { programsLV.programs = DesktopEntries.applications.values }}
                            onTextChanged: {
                                programsLV.programs = searchField.text == "" || searchField.text == undefined ? DesktopEntries.applications.values : DesktopEntries.applications.values.filter(a => a.name.toLowerCase().includes(searchField.text.toLowerCase()))
                            }
                        }
                    }

                    ListView{
                        id: programsLV
                        spacing: 2
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        currentIndex: 1
                        boundsBehavior: Flickable.StopAtBounds
                        boundsMovement: Flickable.StopAtBounds
                        snapMode: ListView.SnapPosition
                        highlightFollowsCurrentItem: true
                        keyNavigationEnabled: false
                        keyNavigationWraps: true

                        clip: true

                        contentHeight: height
                        ScrollIndicator.vertical: ScrollIndicator {
                            active: true

                        }

                        property list<var> programs

                        model: programs
                        delegate: HorizontalAppButton {
                            id: del

                            required property DesktopEntry modelData
                            required property int index
                            Binding { del.selected: del.ListView.isCurrentItem}

                            entry: modelData

                            anchors {
                                horizontalCenter: parent?.horizontalCenter
                            }

                            implicitWidth: parent?.width * .95

                            onHoveredChanged: {
                                programsLV.currentIndex = index
                            }
                            onExecuted: {
                                searchField.clear()
                                root.toggle()
                            }
                        }
                    }

                }
            }
        }

        function toggle() {
            if(startMenuRect.state == "closed") {
                root.visible = true;
                startMenuRect.state = "opened";
            }
            else { startMenuRect.state = "closed" }
        }
    }
}