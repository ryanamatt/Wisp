// qml/GlobalState/WindowState.qml

import Quickshell.Io
import QtQuick

QtObject {
    id: windowState 

    required property string ipcName

    property bool isOpen: false

    function open() { isOpen = true }
    function close() { isOpen = false }
    function toggle() { isOpen = !isOpen }

    property IpcHandler ipc: IpcHandler {
        target: windowState.ipcName
        function open(): void { windowState.open() }
        function close(): void { windowState.close() }
        function toggle(): void { windowState.toggle() }
    }
}