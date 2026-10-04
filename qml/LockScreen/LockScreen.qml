// qml/LockScreen/LockScreen.qml

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../Colors"
import "../Config"
import "../IpcState"
import "../Icons"
import Wisp.Battery
import Wisp.Time

Scope {
    id: root

    // Shared across monitors so every screen mirrors what is typed.
    property string buffer: ""
    property bool failed: false

    // The password box stays hidden until the first keystroke, then remains
    // visible until 30 seconds pass without any typing.
    property bool passwordVisible: false

    // The session lock is engaged by lockActive rather than directly by
    // IpcState, so the desktop can be screenshotted just before locking.
    property bool lockActive: false
    property bool capturing: false
    readonly property string shotDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    function shotPath(name) {
        return shotDir + "/wisp-lock-" + name + ".png"
    }

    // Screenshot every monitor in parallel with grim, then lock.
    function beginLock() {
        if (lockActive || capturing)
            return
        capturing = true
        Battery.refreshAll()
        const cmds = Quickshell.screens.map(
            s => "grim -o '" + s.name + "' '" + shotPath(s.name) + "' &")
        capture.command = ["sh", "-c", cmds.join(" ") + " wait"]
        capture.running = true
        captureTimeout.restart()
    }

    // Always lock, even if grim failed or hung (the background just stays plain).
    function finishCapture() {
        captureTimeout.stop()
        if (!capturing)
            return
        capturing = false
        if (IpcState.lockScreen.locked)
            lockActive = true
    }

    function endLock() {
        capturing = false
        captureTimeout.stop()
        lockActive = false
        // Screenshots can contain sensitive content, so delete them.
        cleanup.command = ["sh", "-c", "rm -f '" + shotDir + "'/wisp-lock-*.png"]
        cleanup.running = true
    }

    Process {
        id: capture
        onExited: root.finishCapture()
    }

    Process {
        id: cleanup
    }

    Timer {
        id: captureTimeout
        interval: 1500
        onTriggered: root.finishCapture()
    }

    Connections {
        target: IpcState.lockScreen
        function onLockedChanged() {
            if (IpcState.lockScreen.locked)
                root.beginLock()
            else
                root.endLock()
        }
    }

    Component.onCompleted: {
        if (IpcState.lockScreen.locked)
            beginLock()
    }

    // Show the password box and (re)start the idle countdown.
    function poke() {
        passwordVisible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 30000
        onTriggered: root.passwordVisible = false
    }

    function submit() {
        if (pam.active || buffer.length === 0)
            return
        failed = false
        pam.start()
    }

    function unlock() {
        buffer = ""
        failed = false
        passwordVisible = false
        hideTimer.stop()
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
                // Keep the box up so the error is visible and a retry is easy.
                root.poke()
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.lockActive

        // One surface is created per screen.
        WlSessionLockSurface {
            id: lockSurface
            // Fallback shown if the screenshot is missing.
            color: Colors.colors.background

            readonly property real screenW: screen ? screen.width : 0

            // Desktop screenshot taken just before locking. Hidden because it
            // is only the source for the blur below.
            Image {
                id: screenshot
                anchors.fill: parent
                source: lockSurface.screen
                    ? "file://" + root.shotPath(lockSurface.screen.name)
                    : ""
                cache: false
                visible: false
                fillMode: Image.PreserveAspectCrop
                // Downscaling makes the blur cheaper and stronger.
                sourceSize.width: Math.round(lockSurface.screenW / 2)
            }

            MultiEffect {
                anchors.fill: parent
                source: screenshot
                blurEnabled: true
                blur: 1.0
                blurMax: 100
                visible: screenshot.status === Image.Ready
            }

            // Dim layer so the text stays readable over bright wallpapers.
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
                visible: screenshot.status === Image.Ready
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Math.round(screenW / 25)

                ColumnLayout {
                    spacing: Math.round(screenW * 0.001)

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
                        id: userBox
                        Layout.preferredWidth: Math.round(lockSurface.screenW * 0.17)
                        Layout.preferredHeight: Math.round(Layout.preferredWidth * 0.15)
                        color: "transparent"
                        radius: width / 5

                        Text {
                            id: userText
                            anchors.centerIn: parent
                            text: Quickshell.env("USER")
                            color: Colors.colors.accent
                            font.pixelSize: Math.min(timeBox.width, timeBox.height)
                            font.family: Config.font
                        }
                    }

                    Rectangle {
                        id: langBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.round(lockSurface.screenW * 0.17)
                        Layout.preferredHeight: Math.round(Layout.preferredWidth * 0.15)
                        color: "transparent"
                        radius: width / 5

                        Text {
                            id: langText
                            anchors.centerIn: parent
                            text: Quickshell.env("LANG").slice(0, 2)
                            color: Colors.colors.accent
                            font.pixelSize: Math.min(langBox.width, langBox.height) / 3
                            font.family: Config.font
                        }
                    }

                }

                ColumnLayout {
                    spacing: 0

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

                        // Use opacity rather than visible so the TextInput keeps
                        // keyboard focus while the box is hidden.
                        opacity: root.passwordVisible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

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
                            passwordCharacter: "∗"
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
                                root.poke()
                            }
                            onAccepted: root.submit()
                            Keys.onEscapePressed: {
                                text = ""
                                root.buffer = ""
                                root.poke()
                            }

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

            } // Top Column Layout

            // Laptop battery pill, top of the screen. Hidden on machines without
            // a laptop battery. Mirrors the bar widget: bolt while charging,
            // laptop icon, then the percentage.
            Rectangle {
                id: batteryBox
                visible: Battery.hasLaptopBattery

                // Horizontal position as a fraction of screen width (0.33 is
                // roughly a third in). The box is centered on that point.
                readonly property real xFraction: 1 / 2
                readonly property bool charging: !!Battery.laptopBattery.charging
                readonly property int percent: Battery.laptopBattery.percent !== undefined
                    ? Battery.laptopBattery.percent
                    : 0
                readonly property real iconSize: Math.round(lockSurface.screenW * 0.014)

                // Pill styling matches the password box.
                readonly property real padX: Math.round(iconSize * 0.9)
                readonly property real padY: Math.round(iconSize * 0.45)

                x: Math.round(lockSurface.screenW * xFraction - width / 2)
                y: Math.round(lockSurface.screenW * 0.03)
                width: batteryRow.implicitWidth + padX * 2
                height: batteryRow.implicitHeight + padY * 2
                radius: height / 2
                color: Colors.colors.surfaceInput
                border.width: 2
                border.color: Colors.colors.border

                RowLayout {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: Math.round(batteryBox.iconSize * 0.3)

                    Image {
                        visible: batteryBox.charging
                        Layout.preferredWidth: batteryBox.iconSize
                        Layout.preferredHeight: batteryBox.iconSize
                        fillMode: Image.PreserveAspectFit
                        source: Icons.getIcon("electricBolt")
                        sourceSize.width: width
                        sourceSize.height: height
                    }

                    Image {
                        Layout.preferredWidth: batteryBox.iconSize
                        Layout.preferredHeight: batteryBox.iconSize
                        fillMode: Image.PreserveAspectFit
                        source: Icons.getIcon("laptop")
                        sourceSize.width: width
                        sourceSize.height: height
                    }

                    Text {
                        text: batteryBox.percent + "%"
                        color: batteryBox.percent <= 20 && !batteryBox.charging
                            ? Colors.colors.error
                            : Colors.colors.accent
                        font.pixelSize: Math.round(batteryBox.iconSize * 0.95)
                        font.family: Config.font
                    }
                }
            }

            Rectangle {
                id: sloganBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(lockSurface.screenW * 0.11)
                width: Math.round(lockSurface.screenW * 0.17)
                height: Math.round(width * 0.15)
                color: "transparent"

                Text {
                    id: sloganText
                    anchors.centerIn: parent
                    text: "Keep Following The Strange Light"
                    color: Colors.colors.accentAlt
                    font.pixelSize: Math.min(sloganBox.width, sloganBox.height) * 0.4
                    font.family: Config.font
                }
            }
        }
    }
}
