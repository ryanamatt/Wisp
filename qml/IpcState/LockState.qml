// qml/IpcState/LockState.qml

import Quickshell.Io
import QtQuick

// Deliberately NOT a WindowState: WindowState exposes close() and toggle()
// over IPC, which would let anything that can run `qs ipc call` unlock the
// session without a password. Here IPC can only lock. Unlocking happens
// solely inside LockScreen.qml after PAM succeeds.
QtObject {
    id: lockState

    required property string ipcName

    property bool locked: false

    function lock() { locked = true }

    property IpcHandler ipc: IpcHandler {
        target: lockState.ipcName
        function lock(): void { lockState.lock() }
    }
}
