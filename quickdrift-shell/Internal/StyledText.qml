import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Internal

Item {
    id: root
    //color:"brown"

    implicitHeight: mainText.implicitHeight
    implicitWidth: mainText.implicitWidth
    Layout.preferredHeight: mainText.implicitHeight
    Layout.preferredWidth: mainText.implicitWidth
    
    property string text
    property alias txt: mainText
    property Text publicText: Text{ }

    // Custom properties matching Text.font sub-properties
    property int pixelSize: Settings.fontPixelSize
    property int weight: Settings.fontWeight
    property color fontColor: Settings.fontColor
    property string family: Settings.fontFamily

    property bool kerning: Settings.fontKerning
    property bool bold: Settings.fontBold
    property bool italic: Settings.fontItalic
    property bool underline: Settings.fontUnderline
    property bool overline: Settings.fontOverline
    property bool strikeout: Settings.fontStrikeout
    property int wrapMode: Settings.fontWrapMode

    // DropShadow properties
    property bool dropShadowOn: Settings.fontDropShadowOn
    property color dropShadowColor: Settings.fontDropShadowColor
    property int dropShadowRadius: Settings.fontDropShadowRadius
    property int dropShadowHoffset: Settings.fontDropShadowHoffset
    property int dropShadowVoffset: Settings.fontDropShadowVoffset

    //anchors.centerIn: parent

    property var textBody: mainText

    Text {
        id: mainText
        //anchors.fill: parent


        
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
            switch (Settings.fontWrapMode) {
                case 0: return Text.NoWrap;
                case 1: return Text.WordWrap;
                case 2: return Text.WrapAnywhere;
                case 3: return Text.Wrap;
                default: return Text.NoWrap;
            }
        }
        //anchors.centerIn: parent
        text: root.text

        // Rectangle{
        //     anchors.fill: parent
        //     color: "brown"
        // }
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
