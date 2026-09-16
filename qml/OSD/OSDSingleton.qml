// qml/OSD/OSDSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
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

    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Keeps sink.audio.volume/muted live.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: (root.sink && root.sink.audio) ? root.sink.audio : null
        function onVolumeChanged() {
            if (!root._ready) return
            root.isVolumeOSDVisible = true
            volumeOSDVisibleTimer.restart()
        }
        function onMutedChanged() {
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
}
