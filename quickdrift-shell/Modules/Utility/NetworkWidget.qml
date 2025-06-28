import Quickshell
import QtQuick
import QtQuick.Layouts
import "root:/Internal/"


Item {
    id: net    
    property string usage
    width: netTxt.implicitWidth + 5
    height: netTxt.implicitHeight
    Layout.preferredWidth: netTxt.implicitWidth + 5
    Layout.preferredHeight: netTxt.implicitHeight

    StyledText {
        id: netTxt
        text: "Network"
    }
}