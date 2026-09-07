pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal

Item {
    id: root

    required property string clipId
    required property string summary
    required property bool isImage
    required property var clipManager

    property bool expanded: ClipboardHistory.isExpanded(clipId)

    readonly property bool pinned: ClipboardHistory.isPinned(clipId)
    readonly property bool pinPending: ClipboardHistory.pinPending(clipId)
    readonly property string decodedText: ClipboardHistory.fullText(clipId)
    readonly property bool decodedTextReady: ClipboardHistory.fullTextReady(clipId)
    readonly property bool decodedTextFailed: ClipboardHistory.fullTextFailed(clipId)
    readonly property string previewSource: ClipboardHistory.previewSource(clipId)
    readonly property bool previewFailed: ClipboardHistory.previewFailed(clipId)

    function toggleExpanded(): void {
        expanded = !expanded
        ClipboardHistory.setExpanded(clipId, expanded)
        if (!expanded)
            return

        if (isImage)
            ClipboardHistory.requestPreview(clipId)
        else
            ClipboardHistory.requestFullText(clipId)
    }

    implicitWidth: ListView.view ? ListView.view.width - 24 : 380
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: cardColumn.implicitHeight + 18
        radius: 10
        color: copyPointer.containsMouse
            ? Settings.surface0
            : Settings.clipmanPopupButtonBackground
        border.width: root.expanded || root.pinned ? 1 : 0
        border.color: root.pinned ? Settings.yellow : Settings.surface1

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 9
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    id: copyArea
                    Layout.fillWidth: true
                    implicitHeight: Math.max(34, summaryText.implicitHeight)

                    RowLayout {
                        anchors.fill: parent
                        spacing: 9

                        Text {
                            text: root.isImage ? "" : ""
                            color: root.isImage ? Settings.mauve : Settings.blue
                            font.family: Settings.fontFamily
                            font.pixelSize: 17
                            Layout.preferredWidth: 22
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            id: summaryText
                            Layout.fillWidth: true
                            text: root.summary
                            color: Settings.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: copyPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ClipboardHistory.copy(root.clipId)
                            root.clipManager.dismiss()
                        }
                    }
                }

                Button {
                    id: pinButton
                    text: root.pinPending ? "" : ""
                    implicitWidth: 32
                    implicitHeight: 32
                    flat: true
                    enabled: !ClipboardHistory.clearing && !ClipboardHistory.pinBusy
                    Accessible.name: root.pinned
                        ? "Unpin clipboard item"
                        : "Pin clipboard item"
                    onClicked: ClipboardHistory.togglePinned(root.clipId)

                    contentItem: Text {
                        text: pinButton.text
                        color: root.pinned ? Settings.yellow : Settings.rosewater
                        font.family: Settings.fontFamily
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: pinButton.hovered ? Settings.surface0 : "transparent"
                    }
                }

                Button {
                    id: expandButton
                    text: root.expanded ? "" : ""
                    implicitWidth: 32
                    implicitHeight: 32
                    flat: true
                    Accessible.name: root.expanded ? "Collapse clipboard item" : "Expand clipboard item"
                    onClicked: root.toggleExpanded()

                    contentItem: Text {
                        text: expandButton.text
                        color: Settings.rosewater
                        font.family: Settings.fontFamily
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: expandButton.hovered ? Settings.surface0 : "transparent"
                    }
                }
            }

            Item {
                visible: root.expanded
                Layout.fillWidth: true
                implicitHeight: visible ? expandedLoader.implicitHeight : 0

                Loader {
                    id: expandedLoader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    active: root.expanded
                    sourceComponent: root.isImage ? imagePreview : textPreview
                }
            }
        }

    }

    Component {
        id: imagePreview

        ColumnLayout {
            implicitHeight: 214
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                radius: 8
                color: Settings.base00
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 6
                    source: root.previewSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.previewSource.length === 0
                    text: root.previewFailed
                        ? "Could not load image preview"
                        : "Loading image preview…"
                    color: Settings.rosewater
                    font.family: Settings.fontFamily
                    font.pixelSize: 12
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Click the card header to copy this image."
                color: Settings.rosewater
                font.family: Settings.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Component {
        id: textPreview

        Rectangle {
            implicitHeight: Math.min(230, Math.max(54, fullText.implicitHeight + 16))
            radius: 8
            color: Settings.base00
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentWidth: width
                contentHeight: fullText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                TextEdit {
                    id: fullText
                    width: parent.width
                    text: root.decodedTextFailed
                        ? "Could not load this clipboard entry."
                        : root.decodedTextReady
                            ? root.decodedText.length > 0
                                ? root.decodedText
                                : "(empty clipboard entry)"
                            : "Loading full clipboard text…"
                    color: Settings.text
                    font.family: Settings.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    readOnly: true
                    selectByMouse: true
                }
            }
        }
    }
}
