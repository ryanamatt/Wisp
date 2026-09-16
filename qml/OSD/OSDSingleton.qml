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
    readonly property var sinkAudio: sink ? sink.audio : null

    // Keeps sink.audio.volume/muted live.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property bool _volumeValueInitialized: false
    property bool _mutedValueInitialized: false

    onSinkAudioChanged: {
        _volumeValueInitialized = false
        _mutedValueInitialized = false
    }

    Connections {
        target: root.sinkAudio
        function onVolumeChanged() {
            if (!root._volumeValueInitialized) {
                root._volumeValueInitialized = true
                return
            }
            root.isVolumeOSDVisible = true
            volumeOSDVisibleTimer.restart()
        }
        function onMutedChanged() {
            if (!root._mutedValueInitialized) {
                root._mutedValueInitialized = true
                return
            }
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
