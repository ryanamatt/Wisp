// qml/OSD/OSDNumLock.qml

import QtQuick
import "../Icons"
import Wisp.Brightness

OSDBase {
    id: root

    Connections {
        target: Brightness
        function onNumLockChanged() { root.show() }
    }

    icon: Brightness.numLockActive ? Icons.getIcon("keyboard/capsLockOn") : Icons.getIcon("keyboard/capsLockOff")

    showBar: false
    valueText: Brightness.numLockActive ? "Num ON" : "Num OFF"
}