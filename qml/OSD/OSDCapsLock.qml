// qml/OSD/OSDCapsLock.qml

import QtQuick
import "../Icons"
import Wisp.Brightness

OSDBase {
    id: root

    Connections {
        target: Brightness
        function onCapsLockChanged() { root.show() }
    }

    icon: Brightness.capsLockActive ? Icons.getIcon("keyboard/capsLockOn") : Icons.getIcon("keyboard/capsLockOff")

    showBar: false
    valueText: Brightness.capsLockActive ? "Caps ON" : "Caps OFF"
}