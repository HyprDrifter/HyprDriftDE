import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Driftlets.SingleWidgets
import qs.Modules.Driftlets.ControlPanel
import qs.Modules.Driftlets.StartMenu
import qs.Modules.Utilities

Scope {
    Variants{
        id: varis
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            property alias leftLayout: leftRowLayout
            property alias centerLayout: centerRowLayout
            property alias rightLayout: rightRowLayout

            property bool vertical: Settings.taskbar.anchors.vertical

            color: "transparent"
            screen: modelData
            anchors {
                top: root.vertical ? Settings.taskbar.anchors.anchorLongWays : Settings.taskbar.anchors.anchorTop
                bottom: root.vertical ? Settings.taskbar.anchors.anchorLongWays :Settings.taskbar.anchors.anchorBottom 
                left: root.vertical ? Settings.taskbar.anchors.anchorLeft : Settings.taskbar.anchors.anchorLongWays
                right: root.vertical ? Settings.taskbar.anchors.anchorRight : Settings.taskbar.anchors.anchorLongWays
            }
            margins {
                top: Settings.taskbar.margins.top
                left: Settings.taskbar.margins.left
                right: Settings.taskbar.margins.right
                bottom: Settings.taskbar.margins.bottom
            }

            onScreenChanged: {
                if(!GlobalStates.taskbarList.includes(root)) { GlobalStates.taskbarList.push(root) }
            }

            implicitHeight: Settings.taskbar.geometry.height
            implicitWidth: Settings.taskbar.geometry.width

            Rectangle {
                
                anchors {
                    fill: parent
                }
                border {
                    color: ThemeSettings.taskbarTrayEnableBorder
                }
                radius:Settings.taskbar.geometry.radius
                color: ThemeSettings.background

                RowLayout{
                    id: mainRowLayout
                    spacing: 0
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    

                    RowLayout {
                        id: leftRowLayout

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignLeft

                        Instantiator {
                            id: leftInstatiator
                            model: Settings.taskbar.taskbarMembersLeft
                            delegate : TaskbarDelegateChooser {
                                //required property var modelData
                                role: "driftlet"
                            }
                            onObjectAdded: (index, object) => mainRowLayout.addChild(leftRowLayout, index, object)

                        }
                    }

                    RowLayout {
                        id: centerRowLayout
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignHCenter

                        Instantiator {
                            id: centerInstatiator
                            model: Settings.taskbar.taskbarMembersCenter
                            delegate : TaskbarDelegateChooser {
                                //required property var modelData
                                role: "driftlet"
                            }
                            onObjectAdded: (index, object) => mainRowLayout.addChild(centerRowLayout, index, object)

                        }

                    }

                    RowLayout {
                        id: rightRowLayout
                        Layout.alignment: Qt.AlignRight

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1

                        Instantiator {
                            id: rightInstatiator
                            model: Settings.taskbar.taskbarMembersRight
                            delegate : TaskbarDelegateChooser {
                                //required property var modelData
                                role: "driftlet"
                            }
                            onObjectAdded: (index, object) => mainRowLayout.addChild(rightRowLayout, index, object)

                        }
                    }

                    function addChild(target: RowLayout, index: int, child: QtObject)
                    {
                        target.children.push(child)
                    }
                }
            }            
        }
    }
}