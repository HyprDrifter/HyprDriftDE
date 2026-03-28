pragma ComponentBehavior: Bound
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls as Controls
import qs.Modules.Driftlets as Driftlets
import qs.Modules.Driftlets.VolumeControls
import qs.Modules.Services

PopupWindow {
    id: root

    required property var parent
    property point anchorPoint
    property PanelWindow containingTaskbar: GlobalStates.taskbarList?.find(t => t.screen == root.screen) ?? null
    property int taskbarGap: Settings.taskbar.margins.popupGap
    property bool isMuted: VolumeBroker.defaultAudioOut?.isMuted ?? true

    onContainingTaskbarChanged: {
        if (root.containingTaskbar != null)
            root.anchorPoint = root.containingTaskbar.mapFromItem(root.parent, 0, 0);
    }

    implicitHeight: 500
    implicitWidth: 500
    mask: Region {
        item: mixerRect
    }
    anchor.item: parent
    anchor.edges: Edges.Top | Edges.Left
    anchor.rect.x: -root.width / 2
    anchor.rect.y: Settings.taskbar.anchors.anchorTop ? 0 + parent.height + root.taskbarGap : (-root.implicitHeight) - anchorPoint.y - root.taskbarGap

    color: "transparent"

    HyprlandFocusGrab {
        id: grabber

        windows: [root]
        onCleared: {
            root.close()
        }
    }

    ClippingRectangle {
        id: mixerRect
        border {
            color: ThemeSettings.taskbarTrayBorderColor
            width: 1
        }
        clip: true
        color: ThemeSettings.mantle
        visible: root.visible
        radius: Settings.taskbar.geometry.radius
        state: "closed"

        Binding { mixerRect.implicitWidth: container.implicitWidth }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 333
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    if (!running && mixerRect.state == "closed") {
                        root.visible = false;
                    }
                }
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 333
                easing.type: Easing.OutQuint
            }
        }

        states: [
            State {
                name: "opened"
                PropertyChanges {
                    mixerRect.implicitHeight: container.implicitHeight
                    grabber.active: true
                }
            },
            State {
                name: "closed"
                PropertyChanges {
                    mixerRect.implicitHeight: 1
                    grabber.active: false
                }
            }
        ]

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        

        ColumnLayout {
            id: container
            spacing: 0
            anchors.fill: parent

            property bool mainView: true
            implicitHeight: mainView ? appView.implicitHeight + tabSelector.implicitHeight : devView.implicitHeight + tabSelector.implicitHeight
            //implicitWidth: root.visible ? (mainView ? appView.implicitWidth + tabSelector.implicitWidth : devView.implicitWidth + tabSelector.implicitWidth) : 1


            Rectangle {
                id: tabSelector

                color: "transparent"
                implicitHeight: tabLayout.implicitHeight
                implicitWidth: tabLayout.implicitWidth
                Layout.fillHeight: true
                Layout.fillWidth: true

                RowLayout {
                    id: tabLayout

                    spacing: 0
                    anchors.fill: parent

                    Controls.Buttons.ButtonDefault {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        backgroundColor: container.mainView || hovered ? ThemeSettings.buttons.backgroundColorHovered : ThemeSettings.buttons.backgroundColor
                        textContent: "Applications"
                    
                        onClicked: {
                            if (!container.mainView) {
                                container.mainView = !container.mainView;
                            }
                        }
                    }

                    Controls.Buttons.ButtonDefault {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        backgroundColor: !container.mainView || hovered ? ThemeSettings.buttons.backgroundColorHovered : ThemeSettings.buttons.backgroundColor
                        textContent: "Devices"

                        onClicked: {
                            if (container.mainView) {
                                container.mainView = !container.mainView;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                implicitHeight: appView.implicitHeight
                implicitWidth: appView.implicitWidth
                visible: container.mainView
                color: "transparent"

                RowLayout {
                    id: appView

                    property var orientation: Qt.Vertical
                    anchors.fill: parent
                    spacing: 0

                    VolumeController {
                        id: volController
                        orientation: appView.orientation
                        controlledAppName: "Master"
                        node: VolumeBroker.defaultAudioOut ? VolumeBroker.defaultAudioOut : null
                    }
                    VolumeController {
                        id: volController2
                        orientation: appView.orientation
                        controlledAppName: "TEST BUTT2"
                    }
                    VolumeController {
                        id: volController3
                        orientation: appView.orientation
                        controlledAppName: "TEST BUTT3"
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                implicitHeight: devView.implicitHeight
                implicitWidth: devView.implicitWidth

                visible: !container.mainView
                color: "transparent"
                ColumnLayout {
                    id: devView

                    property var orientation: Qt.Horizontal
                    anchors.fill: parent
                    spacing: 0

                    VolumeController {
                        id: output
                        orientation: devView.orientation
                        controlledAppName: "TEST BUTT"
                    }
                    VolumeController {
                        id: output2
                        orientation: devView.orientation
                        controlledAppName: "TEST BUTT2"
                    }
                    VolumeController {
                        id: outp3
                        orientation: devView.orientation
                        controlledAppName: "TEST BUTT3"
                    }
                }
            }
        }
    }

    function open() {
        root.visible = true;
        mixerRect.state = "opened";
    }
    function close() {
        mixerRect.state = "closed";
    }
}
