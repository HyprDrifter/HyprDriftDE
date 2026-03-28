import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Internal


Item {
    id: bluth    
    property string usage
    width: bluthTxt.implicitWidth + 5
    height: bluthTxt.implicitHeight
    Layout.preferredWidth: bluthTxt.implicitWidth + 5
    Layout.preferredHeight: bluthTxt.implicitHeight

    StyledText {
        id: bluthTxt

        text: "Bluetooth"
        

    }
}