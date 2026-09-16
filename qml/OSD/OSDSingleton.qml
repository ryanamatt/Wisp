// qml/OSD/OSDSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.Brightness

Singleton {

    property bool isBrightnessOSDVisible: false
    property bool _ready: false

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!_ready) return
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

    Component.onCompleted: Qt.callLater(() => _ready = true)

}
