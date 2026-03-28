import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Configs.Settings
import qs.Modules.Controls

Item {
    id: bluth
    property string status: "Bluetooth"
    width: bluthTxt.implicitWidth + 5
    height: bluthTxt.implicitHeight
    Layout.preferredWidth: bluthTxt.implicitWidth + 5
    Layout.preferredHeight: bluthTxt.implicitHeight

    StyledText {
        id: bluthTxt
        text: bluth.status
    }
}
