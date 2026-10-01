// qml/LockScreen/LockScreen.qml

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import "../Colors"
import "../Config"
import "../IpcState"

Scope {
    id: root

    // Shared across monitors so every screen mirrors what is typed.
    property string buffer: ""
    property bool failed: false

    function submit() {
        if (pam.active || buffer.length === 0)
            return
        failed = false
        pam.start()
    }

    function unlock() {
        buffer = ""
        failed = false
        IpcState.lockScreen.locked = false
    }

    PamContext {
        id: pam

        // PAM service to authenticate against (/etc/pam.d/<config>).
        // "login" exists on virtually every distro.
        config: "login"

        onPamMessage: {
            if (responseRequired)
                respond(root.buffer)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock()
            } else {
                root.buffer = ""
                root.failed = true
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: IpcState.lockScreen.locked

        // One surface is created per screen.
        WlSessionLockSurface {
            color: Colors.colors.background

            Rectangle {
                id: box
                anchors.centerIn: parent
                width: 320
                height: 48
                radius: 12
                color: Colors.colors.surfaceInput
                border.width: 2
                border.color: root.failed
                    ? Colors.colors.error
                    : input.activeFocus
                        ? Colors.colors.borderActive
                        : Colors.colors.border

                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text.length === 0
                    text: pam.active ? "Checking..." : "Password"
                    color: Colors.colors.foregroundSubtle
                    font.pixelSize: 16
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "\u2022"
                    color: Colors.colors.foreground
                    selectionColor: Colors.colors.selected
                    selectedTextColor: Colors.colors.foreground
                    font.pixelSize: 16
                    clip: true
                    focus: true
                    enabled: !pam.active

                    onTextEdited: {
                        root.failed = false
                        root.buffer = text
                    }
                    onAccepted: root.submit()
                    Keys.onEscapePressed: { text = ""; root.buffer = "" }

                    // Keep this field in sync when another monitor is typed
                    // into, or when the buffer is cleared after a failure.
                    Connections {
                        target: root
                        function onBufferChanged() {
                            if (input.text !== root.buffer)
                                input.text = root.buffer
                        }
                    }

                    Component.onCompleted: forceActiveFocus()
                    onEnabledChanged: if (enabled) forceActiveFocus()
                }
            }

            Text {
                anchors.top: box.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: box.horizontalCenter
                text: "Incorrect password"
                color: Colors.colors.error
                font.pixelSize: 14
                opacity: root.failed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }
}
