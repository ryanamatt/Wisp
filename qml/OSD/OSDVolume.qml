// qml/OSD/OSDVolume.qml

import QtQuick
import "../Icons"
import Wisp.Audio

OSDBase {
    id: root
    
    readonly property bool muted: Audio.sinkMuted
    readonly property int volumePercent: Math.round(Audio.sinkVolume * 100)

    Connections {
        target: Audio
        function onSinkChanged() { root.show() }
    }

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
