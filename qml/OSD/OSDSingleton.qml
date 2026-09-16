// qml/OSD/OSDSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.Brightness

Singleton {

    property bool isBrightnessOSDVisible: false

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            isBrightnessOSDVisible = true
            brightnessOSDVisibleTimer.restart()
        }
    }

    Timer {
        id: brightnessOSDVisibleTimer
        interval: 1000
        repeat: false
        onTriggered: isBrightnessOSDVisible = false
    }

}
