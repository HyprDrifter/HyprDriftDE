import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Configs.Settings
import qs.Modules.Controls

Item {
    id: net
    property string status: "Network"
    width: netTxt.implicitWidth + 5
    height: netTxt.implicitHeight
    Layout.preferredWidth: netTxt.implicitWidth + 5
    Layout.preferredHeight: netTxt.implicitHeight

    StyledText {
        id: netTxt
        text: net.status
    }
}
