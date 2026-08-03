// qml/GlobalState/GlobalState.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: globalState

    // ----- App Launcher -----

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

    // ----- Power Menu -----

    property bool isPowerMenuOpen: false
    property var powerMenuScreen: null

    function openPowerMenu() {
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

        globalState.powerMenuScreen = targetScreen || Quickshell.screens[0]
        globalState.isPowerMenuOpen = true
    }

    function closePowerMenu() {
        globalState.isPowerMenuOpen = false
        globalState.powerMenuScreen = null
    }

    function togglePowerMenu() {
        if (globalState.isPowerMenuOpen)
            globalState.closePowerMenu()
        else
            globalState.openPowerMenu()
    }

    IpcHandler {
        target: "powerMenu"
        function open(): void { globalState.openPowerMenu() }
        function close(): void { globalState.closePowerMenu() }
        function toggle(): void { globalState.togglePowerMenu() }
    }

}
