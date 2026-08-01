// qml/GlobalState/GlobalState.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: globalState

    property bool isAppLauncherOpen: false
    property var appLauncherScreen: null

    function openAppLauncher() {
        const focused = Hyprland.focusedMonitor
        let targetScreen = null

        if (focused) {
            for (const screen of Quickshell.screens) {
                if (screen.name === focused.name) {
                    targetScreen = screen
                    break
                }
            }
        }

        globalState.appLauncherScreen = targetScreen || Quickshell.screens[0]
        globalState.isAppLauncherOpen = true
    }

    function closeAppLauncher() {
        globalState.isAppLauncherOpen = false
        globalState.appLauncherScreen = null
    }

    function toggleAppLauncher() {
        if (globalState.isAppLauncherOpen)
            globalState.closeAppLauncher()
        else
            globalState.openAppLauncher()
    }

    IpcHandler {
        target: "appLauncher"
        function open(): void { globalState.openAppLauncher() }
        function close(): void { globalState.closeAppLauncher() }
        function toggle(): void { globalState.toggleAppLauncher() }
    }

}
