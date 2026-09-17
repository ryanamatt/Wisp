// qml/OSD/OSDMic.qml

import "../Icons"
import Quickshell.Services.Pipewire

OSDBase {
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: (source && source.audio) ? source.audio.muted : false

    whenVisible: OSDSingleton.isMicOSDVisible

    icon: muted ? Icons.getIcon("audio/micOff") : Icons.getIcon("audio/mic")

    showBar: false
    valueText: muted ? "Muted" : "Unmuted"
}
