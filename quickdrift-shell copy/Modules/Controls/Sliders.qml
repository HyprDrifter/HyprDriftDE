pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQml

import Quickshell

import qs.Configs
import qs.Modules.Controls.Sliders as Sliders
import qs.Modules.Driftlets

Singleton {
    id: root

    component DefaultSlider : Sliders.DefaultSlider { }
    property Component defaultSliderComponent: Component { Sliders.DefaultSlider { } }

}