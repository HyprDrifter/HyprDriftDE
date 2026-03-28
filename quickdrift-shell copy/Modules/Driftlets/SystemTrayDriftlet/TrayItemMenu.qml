pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Configs
import qs.Configs.Settings
import qs.Modules.Controls.Buttons

PopupWindow {
    id: root

    required property var parent
    property var itemMenu: parent?.trayItem?.menu ?? undefined
    property PanelWindow containingTaskbar: GlobalStates.taskbarList?.find(t => t.screen == root.screen) ?? null
    property list<QtObject> menuItems: []
    property int taskbarGap: 0
    property point anchorPoint

    onContainingTaskbarChanged: {
        if (root.containingTaskbar != null)
            root.anchorPoint = root.containingTaskbar.mapFromItem(root.parent, 0, 0);
    }

    color: "transparent"
    anchor.item: parent
    anchor.rect.x: 0 - root.width / 2
    anchor.rect.y: (-root.height) - anchorPoint.y - Settings.taskbar.margins.popupGap
    visible: false
    anchor.edges: Edges.Top | Edges.Left
    implicitWidth: 500
    implicitHeight: 1000
    mask: Region { item: menuRect}

    HyprlandFocusGrab {
        id: grabb
        windows: [root]
        active: true
        onCleared: {
            menuRect.implicitHeight = 1
            root.visible = false;
        }
    }

    onVisibleChanged: {
        if (root.visible) {
            grabb.active = true;
        } else {
            grabb.active = false;
        }
    }

    QsMenuOpener {
        id: menu
        menu: root.itemMenu ? root.itemMenu : null
    }

    Instantiator {
        id: menuItemsInstantiator

        model: menu.children
        delegate: QtObject {
            id: objDel

            required property QsMenuEntry modelData
            property string isSepString: item.isSeparator ? "true" : "false" ?? "false"
            property QsMenuEntry item: modelData
        }
        onObjectAdded: (index, object) => root.menuItems.push(object)
    }

    Rectangle {
        id: menuRect
        color: ThemeSettings.background
        radius: 0 // Settings.taskbar.geometry.radius
        border {
            width: 1
            color: ThemeSettings.taskbarTrayBorderColor
        }
        visible: parent.visible

        anchors{

            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        Behavior on implicitHeight {

            NumberAnimation {
                duration: 333
                easing.type: Easing.OutQuint
            }
        }

        implicitWidth: menuLayout.implicitWidth
        implicitHeight: menuLayout.implicitHeight

        ColumnLayout {
            id: menuLayout
            visible: root.visible
            anchors.fill: parent

            spacing: 0
            onChildrenChanged: {
                var nwidth = menuLayout.children.reduce((prev, current) => (prev && prev.combinedWidth > current.combinedWidth) ? prev : current).combinedWidth;
                if (nwidth > 0 && nwidth > menuLayout.width) {
                    menuLayout.width = nwidth * 1.75;
                }
            }

            Instantiator {
                id: columnInstantiator

                model: root.menuItems
                delegate: DelegateChooser {
                    id: del
                    role: "isSepString"

                    DelegateChoice {
                        roleValue: "true"
                        delegate: Component {
                            Rectangle {
                                parent: menuLayout
                                required property var modelData
                                property QtObject item: modelData
                                Layout.fillWidth: true
                                Layout.minimumWidth: 10
                                Layout.preferredHeight: 1
                                Layout.alignment: Qt.AlignCenter
                                visible: parent.visible
                                color: ThemeSettings.taskbarTrayBorderColor
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "false"
                        delegate: HorizontalIconTextButton {
                            id: btn
                            required property var modelData
                            parent: menuLayout
                            entry: modelData
                            imageContentPath: btn.modelData?.item?.icon ?? ""
                            selected: hovered
                            radius: 0 // Settings.taskbar.geometry.radius
                            textContent: btn.modelData?.item?.text ?? ""
                            implicitWidth: btn.btnWidth * 1.3
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            borderWidth: 0
                            enabled: entry.item.enabled

                            onClicked: {
                                btn.entry.item.triggered();
                                root.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    function open() {
        root.visible = true;
        menuRect.implicitHeight = menuLayout.implicitHeight
    }
}
