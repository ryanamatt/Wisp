// qml/GlobalState/GlobalState.qml

pragma Singleton

import Quickshell
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

}
