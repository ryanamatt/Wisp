// qml/OSD/OSDMic.qml

import "../Icons"
import Wisp.Audio

OSDBase {
    readonly property bool muted: Audio.sourceMuted

    whenVisible: OSDSingleton.isMicOSDVisible

    icon: muted ? Icons.getIcon("audio/micOff") : Icons.getIcon("audio/mic")

    showBar: false
    valueText: muted ? "Muted" : "Unmuted"
}
