// qml/GlobalState/GlobalState.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: globalState

    property PopupState timeWorkspace: PopupState { ipcName: "calendar" }
    property PopupState appLauncher: PopupState { ipcName: "appLauncher" }
    property PopupState powerMenu: PopupState { ipcName: "powerMenu" }
    property PopupState audioWidget: PopupState { ipcName: "audioPlayer" }
    property PopupState systemMonitorWidget: PopupState { ipcName: "systemMonitor" }
    property PopupState clipboardWidget: PopupState { ipcName: "clipboard" }
    property PopupState networkWidget: PopupState { ipcName: "network" }

    QtObject {
        id: themeSwitcherState

        property bool isOpen: false

        function open() { isOpen = true }
        function close() { isOpen = false }
        function toggle() { isOpen = !isOpen }

        property IpcHandler ipc: IpcHandler {
            target: "themeSwitcher"
            function open(): void { themeSwitcherState.open() }
            function close(): void { themeSwitcherState.close() }
            function toggle(): void { themeSwitcherState.toggle() }
        }
    }

    property alias themeSwitcher: themeSwitcherState
}
