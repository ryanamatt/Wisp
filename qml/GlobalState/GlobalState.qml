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
    property PopupState brightnessWidget: PopupState { ipcName: "brightness" }
    property PopupState batteryWidget: PopupState { ipcName: "battery" }

    property WindowState themeSwitcher: WindowState { ipcName: "themeSwitcher" }
    property WindowState workspaceSwitcher: WindowState { ipcName: "workspaceSwitcher" }
    property WindowState commandCenter: WindowState { ipcName: "commandCenter" }
    property WindowState screenshot: WindowState { ipcName: "screenshot" }
}
