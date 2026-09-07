import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Internal
import qs.Services

Item {
    id: root

    required property PwNode node
    property bool master: false
    property int maximumVolume: master
        ? Settings.audioProtection
            ? Settings.audioMaxVolume
            : 200
        : 100

    readonly property var nodeProperties: node?.properties ?? ({})
    readonly property int volumePercent: master
        ? AudioControl.currentVolume
        : node?.audio
            ? Math.round(node.audio.volume * 100)
            : 0
    readonly property bool muted: master
        ? AudioControl.muted
        : node?.audio?.muted ?? false
    readonly property string title: {
        if (master)
            return "System"

        const applicationName = propertyText("application.name")
        if (applicationName.length > 0)
            return applicationName

        const nickname = String(node?.nickname || "").trim()
        if (nickname.length > 0)
            return nickname

        const description = String(node?.description || "").trim()
        if (description.length > 0)
            return description

        const name = String(node?.name || "").trim()
        return name.length > 0 ? name : "Application"
    }
    readonly property string subtitle: {
        if (master) {
            const deviceName = String(node?.description || "").trim()
            return deviceName.length > 0 ? deviceName : "Default output"
        }

        const mediaName = propertyText("media.name")
        if (mediaName.length > 0 && mediaName !== title)
            return mediaName

        const description = String(node?.description || "").trim()
        return description !== title ? description : ""
    }

    function propertyText(key): string {
        const value = nodeProperties[key]
        return value === undefined || value === null
            ? ""
            : String(value).trim()
    }

    function setVolume(percent): void {
        if (!node?.audio)
            return

        const safePercent = Math.max(0,
            Math.min(maximumVolume, Number(percent) || 0))

        if (master) {
            AudioControl.setMasterVolumePercent(safePercent)
            return
        }

        node.audio.volume = safePercent / 100
    }

    function syncSliderVolume(): void {
        // Slider writes replace its declarative value binding while it is
        // being manipulated. Resync explicitly so later PipeWire changes
        // (including the system volume hotkeys) remain visible.
        if (!volumeSlider.pressed)
            volumeSlider.value = volumePercent
    }

    function enforceApplicationMaximum(): void {
        if (master || !node?.audio)
            return

        if (node.audio.volume > 1)
            node.audio.volume = 1
    }

    function toggleMute(): void {
        if (!node?.audio)
            return

        if (master) {
            AudioControl.toggleMasterMute()
            return
        }

        node.audio.muted = !node.audio.muted
    }

    implicitWidth: Settings.volumeMixerChannelWidth
    implicitHeight: channelLayout.implicitHeight

    PwObjectTracker {
        objects: [root.node]
    }

    Connections {
        target: root.node?.audio ?? null

        function onVolumeChanged(): void {
            root.enforceApplicationMaximum()
        }
    }

    onVolumePercentChanged: syncSliderVolume()

    Component.onCompleted: Qt.callLater(() => {
        enforceApplicationMaximum()
        syncSliderVolume()
    })

    ColumnLayout {
        id: channelLayout

        anchors.fill: parent
        spacing: 6

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            text: root.title
            color: Settings.text
            font.family: Settings.fontFamily
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            text: root.subtitle
            color: Settings.rosewater
            font.family: Settings.fontFamily
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.muted ? "Muted" : root.volumePercent + "%"
            color: root.muted ? Settings.red : Settings.flamingo
            font.family: Settings.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }

        Slider {
            id: volumeSlider

            Layout.preferredHeight: Settings.volumeMixerSliderHeight
            Layout.preferredWidth: 34
            Layout.alignment: Qt.AlignHCenter
            orientation: Qt.Vertical
            from: 0
            to: root.maximumVolume
            stepSize: Settings.audioVolumeStep
            wheelEnabled: true
            live: true
            value: 0
            enabled: Boolean(root.node?.audio)
            Accessible.name: root.title + " volume"
            Accessible.description: root.volumePercent + " percent"

            onMoved: root.setVolume(value)
            onPressedChanged: {
                if (!pressed)
                    root.syncSliderVolume()
            }

            background: Rectangle {
                x: volumeSlider.leftPadding
                    + (volumeSlider.availableWidth - width) / 2
                y: volumeSlider.topPadding
                implicitWidth: Settings.volumeMixerSliderWidth
                implicitHeight: volumeSlider.availableHeight
                width: implicitWidth
                height: implicitHeight
                radius: 7
                color: Settings.mantle
                border.width: 1
                border.color: Settings.surface1

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * volumeSlider.position
                    radius: parent.radius
                    color: root.muted ? Settings.surface2 : Settings.flamingo
                }
            }

            handle: Rectangle {
                x: volumeSlider.leftPadding
                    + (volumeSlider.availableWidth - width) / 2
                y: volumeSlider.topPadding
                    + (1 - volumeSlider.position)
                        * (volumeSlider.availableHeight - height)
                implicitWidth: 24
                implicitHeight: 8
                radius: 4
                color: root.muted ? Settings.surface2 : Settings.flamingo
                border.width: 1
                border.color: Settings.background
            }
        }

        Button {
            id: muteButton

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 38
            implicitHeight: 30
            flat: true
            enabled: Boolean(root.node?.audio)
            Accessible.name: (root.muted ? "Unmute " : "Mute ") + root.title
            onClicked: root.toggleMute()

            contentItem: Text {
                text: root.muted ? "󰖁" : "󰕾"
                color: root.muted ? Settings.red : Settings.flamingo
                font.family: Settings.fontFamily
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: muteButton.hovered
                    ? Settings.surface1
                    : Settings.surface0
            }
        }
    }
}
