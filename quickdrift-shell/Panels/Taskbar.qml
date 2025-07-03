import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import QtQuick.Controls
import Quickshell.Widgets
import "root:/Modules"
import "root:/Internal"
import "root:/Modules/Performance"
import "root:/Modules/Interactive"
import "root:/Modules/Interactive/ClipboardManager"
import "root:/Modules/Interactive/ApplicationLauncher"
import "root:/Modules/Interactive/VolumeController"
import "root:/Modules/Utility"


Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            screen: modelData
            property var modelData
            color: "transparent"
            
            onVisibleChanged: {
                if(visible){
                    panelScaleAnimator.from = .1
                    panelScaleAnimator.to = 1
                    panelScaleAnimator.running = true;
                }
            }

            ScaleAnimator {
                id: panelScaleAnimator
                target: leftPanel
                from: .1
                to: 1
                duration: 500
                easing.type: Easing.OutBack
            }

            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: Settings.taskbarTopGap
                left: Settings.taskbarLeftGap
                right: Settings.taskbarRightGap
            }
            implicitHeight: Settings.taskbarHeight

            Rectangle {
                id: leftPanel

                radius: Settings.taskbarRadius
                color: Settings.taskbarColor
                anchors.fill: parent
                anchors.centerIn: parent
                
                //anchors.fill: parent
                RowLayout {
                    id: sectionContainer
                    anchors.fill: parent
                    spacing: 10
                    WrapperRectangle {
                        //implicitWidth: leftRowLayout.implicitWidth
                        color: "transparent"
                        RowLayout {
                            id: leftRowLayout
                            spacing: 15
                            Layout.maximumWidth: panel.width / 3
                            WrapperRectangle {
                                id: containerRect
                                color: "transparent"

                                //Layout.fillWidth: true
                                //Layout.fillHeight: true

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    spacing: 10

                                    LauncherButton { }
                                    
                                    //Spacer {}
                                    WorkspaceManager { bar: panel}
                                    //Spacer {}
                                    ActiveWindowWidget {
                                        bar: panel
                                        //anchors.centerIn: panel
                                    } 
                                }
                            }
                        }
                    }

                    Spacer {}

                    RowLayout {
                        id: centerRowLayout
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.maximumWidth: panel.width / 3
                        anchors.horizontalCenter: panel
                        Spacer {}
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: "transparent"
                            RowLayout {
                                id: middleRowLayout
                                anchors.fill: parent
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Spacer {}

                    RowLayout {
                        id: rightRowLayout
                        spacing: 0
                        implicitHeight: rightRowInnerLayout.implicitHeight
                        //anchors.verticalCenter: parent.verticalCenter
                        Layout.preferredHeight: parent.implicitHeight
                        anchors.right: parent.right

                        WrapperRectangle {
                            id: rightRowLayoutRectangle
                            color: "transparent"
                            //Layout.fillWidth: true
                            //Layout.fillHeight: true
                            //Layout.preferredWidth: rightRowInnerLayout.implicitWidth
                            //Layout.preferredHeight: rightRowInnerLayout.implicitHeight

                            RowLayout {
                                id: rightRowInnerLayout
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 15
                                anchors.rightMargin: 15
                                anchors.right: parent.right
                                //anchors.bottom: parent.bottom
                                //anchors.top: parent.top
                                spacing: 8

                                CpuWidget {}
                                RamWidget {}
                                GpuWidget {}
                                NetworkWidget {}
                                BluetoothWidget {}
                                VolumeController {bar: panel}
                                Button {
                                    id: clipboardBtn
                                    Layout.preferredHeight: parent.height 
                                    Layout.preferredWidth: Layout.preferredHeight
                                    ClipboardManager {
                                        id: clipMenu
                                        moveToItem: clipBtnArea
                                    }
                                    icon.name: "󰅌" // NerdFont clipboard   
                                    //text: "󰅌"
                                    StyledTextLarge{
                                        id: clipBtnTxt
                                        text: "󰅌"
                                        anchors.centerIn: clipboardBtn
                                        //txt.anchors.centerIn: clipBtnTxt
                                    }                                
                                    
                                    background: WrapperRectangle{
                                        radius: 8
                                        anchors.topMargin: 5
                                        anchors.bottomMargin: 5
                                        color: parent.hovered ? Settings.clipmanIconBackgroundHover : Settings.clipmanIconBackground
                                        anchors.fill: parent
                                    }
                                    WrapperMouseArea {
                                        id: clipBtnArea
                                        anchors.fill: parent
                                        onClicked: {
                                            clipMenu.visible = !clipMenu.visible
                                            //clipMenu.anchor.window = panel
                                        }
                                    }
                                }
                                SysTray {
                                    bar: panel
                                }
                                PowerButton {}
                                ClockWidget {}
                            }
                        }
                    }
                }
            }
        }
    }
}
