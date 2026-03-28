import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Configs.Settings

Item {
    id: root

    implicitHeight: mainText.implicitHeight
    implicitWidth: mainText.implicitWidth
    Layout.preferredHeight: mainText.implicitHeight
    Layout.preferredWidth: mainText.implicitWidth

    property string text
    property alias txt: mainText
    property Text publicText: Text { }

    // Custom properties matching Text.font sub-properties
    property int pixelSize: ThemeSettings.fontPixelSize
    property int weight: ThemeSettings.fontWeight
    property color fontColor: ThemeSettings.fontColor
    property string family: ThemeSettings.fontFamily

    property bool kerning: ThemeSettings.fontKerning
    property bool bold: ThemeSettings.fontBold
    property bool italic: ThemeSettings.fontItalic
    property bool underline: ThemeSettings.fontUnderline
    property bool overline: ThemeSettings.fontOverline
    property bool strikeout: ThemeSettings.fontStrikeout
    property int wrapMode: ThemeSettings.fontWrapMode

    // DropShadow properties
    property bool dropShadowOn: ThemeSettings.fontDropShadowOn
    property color dropShadowColor: ThemeSettings.fontDropShadowColor
    property int dropShadowRadius: ThemeSettings.fontDropShadowRadius
    property int dropShadowHoffset: ThemeSettings.fontDropShadowHoffset
    property int dropShadowVoffset: ThemeSettings.fontDropShadowVoffset

    property var textBody: mainText

    Text {
        id: mainText

        font.pixelSize: root.pixelSize
        font.weight: root.weight
        color: root.fontColor
        font.family: root.family

        font.kerning: root.kerning
        font.bold: root.bold
        font.italic: root.italic
        font.underline: root.underline
        font.overline: root.overline
        font.strikeout: root.strikeout
        wrapMode: {
            switch (ThemeSettings.fontWrapMode) {
                case 0: return Text.NoWrap;
                case 1: return Text.WordWrap;
                case 2: return Text.WrapAnywhere;
                case 3: return Text.Wrap;
                default: return Text.NoWrap;
            }
        }
        text: root.text
    }

    DropShadow {
        anchors.fill: mainText
        source: mainText

        visible: root.dropShadowOn
        color: root.dropShadowColor
        radius: root.dropShadowRadius
        horizontalOffset: root.dropShadowHoffset
        verticalOffset: root.dropShadowVoffset
    }
}
