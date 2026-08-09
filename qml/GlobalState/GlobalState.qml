// qml/GlobalState/GlobalState.qml

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: globalState

    property PopupState appLauncher: PopupState { ipcName: "appLauncher" }
    property PopupState powerMenu: PopupState { ipcName: "powerMenu" }
    property PopupState switcherWidget: PopupState { ipcName: "themeSwitcher" }
    property PopupState audioWidget: PopupState { ipcName: "audioPlayer" }
    property PopupState systemMonitorWidget: PopupState { ipcName: "systemMonitor" }

}
