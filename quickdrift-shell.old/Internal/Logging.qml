import qs.Internal
import qs.Services
import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

//pragma ComponentBehavior: Bound

Scope {
    id: root

    property string temp
    property SystemTray sysTray: SystemTray
    property var sysTrayHolder
    //readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property var tops: ToplevelManager.toplevels.values[0]

    Timer {
        interval: 3000  // 1 second
        running: true
        repeat: true
        //onTriggered: testLog.running = true,console.log(temp)
        onTriggered: root.logging()
    }

    function logging() {
        console.log("------------------------------------------------------------")
        // for(let i in tops)
        // {
            var item = tops
            console.log(`Checking : ${item.title}  - ${item.appId}`)
            console.log(`minimized :  ${item.minimized}`)
            if(item.minimized)
            {
                console.log("It is minimized.")
                // item.minimized=true
                //console.log("set true")
            }

            if(!item.minimized)
            {
                console.log("not minimized. settings to true")
                item.minimized.true
                console.log("set true")
            }
            
            console.log("-----------------------")
        //}
    }








}