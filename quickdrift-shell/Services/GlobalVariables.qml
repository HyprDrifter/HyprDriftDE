pragma Singleton

import Quickshell
import QtQuick
import qs.Internal

Singleton{
    id: root

    property bool launcherOpen: false

    property bool minimizeManagerVisible: false

    property var randomItems: [
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) },
        { id: Math.floor(Math.random() * 1000000) }
    ]
}