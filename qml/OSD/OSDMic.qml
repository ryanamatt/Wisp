// qml/OSD/OSDMic.qml

import QtQuick
import "../Icons"
import Wisp.Audio

OSDBase {
    id: root
    
    readonly property bool muted: Audio.sourceMuted

    Connections {
        target: Audio
        function onSourceChanged() { root.show() }
    }

    icon: muted ? Icons.getIcon("audio/micOff") : Icons.getIcon("audio/mic")

    showBar: false
    valueText: muted ? "Muted" : "Unmuted"
}
