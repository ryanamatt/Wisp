// qml/OSD/OSDVolume.qml

import "../Icons"
import Wisp.Audio

OSDBase {
    readonly property bool muted: Audio.sinkMuted
    readonly property int volumePercent: Math.round(Audio.sinkVolume * 100)

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
