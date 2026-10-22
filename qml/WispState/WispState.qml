// qml/WispState/WispState.qml

pragma Singleton

import QtQuick
import Quickshell
import Wisp.System

Singleton {
    id: wispState

    property bool gameMode: false

    function toggleGameMode() {
        if (wispState.gameMode) {
            wispState.gameMode = false

            SystemMonitor.setLowPowerMode(wispState.gameMode)

            return
        }

        wispState.gameMode = true
        SystemMonitor.setLowPowerMode(wispState.gameMode)
    }
}

