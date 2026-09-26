// qml/OSD/OSDSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Wisp.Audio
import Wisp.Brightness

Singleton {
    id: root

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => _ready = true)

    // ----- Brightness OSD -----
    property bool isBrightnessOSDVisible: false

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            if (!root._ready) return
            root.isBrightnessOSDVisible = true
            brightnessOSDVisibleTimer.restart()
        }
    }

    Timer {
        id: brightnessOSDVisibleTimer
        interval: 1000
        repeat: false
        onTriggered: root.isBrightnessOSDVisible = false
    }

    // ----- Volume OSD -----
    property bool isVolumeOSDVisible: false

    Connections {
        target: Audio
        function onSinkChanged() {
            if (!root._ready) return
            root.isVolumeOSDVisible = true
            volumeOSDVisibleTimer.restart()
        }
    }

    Timer {
        id: volumeOSDVisibleTimer
        interval: 1000
        repeat: false
        onTriggered: root.isVolumeOSDVisible = false
    }

    // ----- Mic OSD -----
    property bool isMicOSDVisible: false

    Connections {
        target: Audio
        function onSourceChanged() {
            if (!root._ready) return
            root.isMicOSDVisible = true
            micOSDVisibleTimer.restart()
        }
    }

    Timer {
        id: micOSDVisibleTimer
        interval: 1000
        repeat: false
        onTriggered: root.isMicOSDVisible = false
    }
}
