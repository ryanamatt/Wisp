// qml/OSD/OSDVolume.qml

import "../Icons"
import Quickshell.Services.Pipewire

OSDBase {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property int volumePercent: Math.round(volume * 100)

    whenVisible: OSDSingleton.isVolumeOSDVisible

    icon: {
        if (muted || volumePercent === 0)
            return Icons.getIcon("audio/volumeOff")
        if (volumePercent < 30)
            return Icons.getIcon("audio/volumeDown")
        return Icons.getIcon("audio/volumeUp")
    }

    barValue: muted ? 0 : volumePercent
    valueText: (muted ? 0 : volumePercent) + "%"
}
