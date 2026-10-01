// qml/LockScreen/LockScreen.qml

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts
import "../Colors"
import "../Config"
import "../IpcState"
import Wisp.Time

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
            id: lockSurface
            color: Colors.colors.background

            readonly property real screenW: screen ? screen.width : 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Math.round(screenW / 25)

                Rectangle {
                    id: timeBox
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.round(lockSurface.screenW * 0.17)
                    Layout.preferredHeight: Math.round(Layout.preferredWidth * 0.15)
                    color: "transparent"

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: Time.time
                        color: Colors.colors.accent
                        font.pixelSize: Math.min(timeBox.width, timeBox.height)
                        font.family: Config.font
                    }
                }

                Rectangle {
                    id: passwordBox
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.round(lockSurface.screenW * 0.17)
                    Layout.preferredHeight: Math.round(Layout.preferredWidth * 0.15)
                    radius: height * 0.25
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
                        font.family: Config.font
                    }

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "*"
                        color: Colors.colors.foreground
                        selectionColor: Colors.colors.selected
                        selectedTextColor: Colors.colors.foreground
                        font.pixelSize: 16
                        font.family: Config.font
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
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    text: "Incorrect password"
                    color: Colors.colors.error
                    font.pixelSize: 14
                    font.family: Config.font
                    opacity: root.failed ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
