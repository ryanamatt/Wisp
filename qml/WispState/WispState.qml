// qml/WispState/WispState.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Wisp.System

Singleton {
    id: wispState

    property bool gameMode: false

    Process {
        id: hyprGameMode
        command: ["sh", "-c", "hyprctl repl 'gameMode()'"]
    }

    function toggleGameMode() {
        wispState.gameMode = !wispState.gameMode

        SystemMonitor.setLowPowerMode(wispState.gameMode)
        hyprGameMode.running = true

    }
}

