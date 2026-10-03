// qml/OSD/OSDBrightness.qml

import QtQuick
import "../Icons"
import Wisp.Brightness

OSDBase {
    id: root

    Connections {
        target: Brightness
        function onBrightnessChanged() { root.show() }
    }

    icon: Icons.getIcon("brightness")
    
    barValue: Brightness.brightnessPercent
    valueText: Brightness.brightnessPercent + "%"
}
