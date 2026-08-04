// qml/GlobalState/PopupState.qml

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: popupState

    // Name this popup is reachable under via `qs ipc call <ipcName> ...`.
    required property string ipcName

    property bool isOpen: false
    property var screen: null

    // True when this popup is open AND it's open on targetScreen. Widgets
    // are instantiated once per monitor but this state is shared across all
    // of them, so this is what tells a given widget instance "that's me".
    function isOpenOn(targetScreen) {
        return popupState.isOpen && popupState.screen === targetScreen
    }

    // Falls back to the focused monitor (or the first screen) when no
    // explicit screen is given, e.g. when triggered over IPC.
    function resolveScreen(preferredScreen) {
        if (preferredScreen)
            return preferredScreen

        const focused = Hyprland.focusedMonitor
        if (focused) {
            for (const s of Quickshell.screens) {
                if (s.name === focused.name)
                    return s
            }
        }
        return Quickshell.screens[0]
    }

    function open(targetScreen) {
        popupState.screen = popupState.resolveScreen(targetScreen)
        popupState.isOpen = true
    }

    function close() {
        popupState.isOpen = false
        popupState.screen = null
    }

    function toggle(targetScreen) {
        if (popupState.isOpen)
            popupState.close()
        else
            popupState.open(targetScreen)
    }

    property IpcHandler ipc: IpcHandler {
        target: popupState.ipcName
        function open(): void { popupState.open(null) }
        function close(): void { popupState.close() }
        function toggle(): void { popupState.toggle(null) }
    }
}
