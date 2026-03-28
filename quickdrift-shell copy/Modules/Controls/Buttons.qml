pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQml

import Quickshell

import qs.Configs
import qs.Modules.Controls.Buttons as Buttons

Singleton {
    id: root

    component ButtonDefault : Buttons.ButtonDefault { }
    property Component buttonDefaultComponent: Component { Buttons.ButtonDefault { } }
    property Component hAppButtonComponent: Component { Buttons.HorizontalAppButton { } }
    property Component hIconTextButtonComponent: Component { Buttons.HorizontalIconTextButton { } }

    // Buttons.ButtonDefault { }
}