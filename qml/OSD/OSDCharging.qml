// qml/OSD/OSDCharging.qml

import QtQuick
import "../Icons"
import Wisp.Battery

OSDBase {
    id: root

    Connections {
        target: Battery
        function onDeviceChargingChanged(name, icon, percent, charging) {
            root.icon = Icons.getIcon(icon)
            root.barValue = percent
            root.valueText = name + (charging ? " plugging in" : " unplugged") + " (" + percent + "%)"
            root.show()
        }
    }

    showBar: true
}

