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

            // Scale unit: 1.0 at 1920px wide. All sizes below are written
            // as "pixels at 1080p" and scale with the monitor.
            readonly property real u: screenW > 0 ? screenW / 1920 : 1

            // Used to fade the content in when the lock appears.
            property bool shown: false
            Component.onCompleted: shown = true

            // Glassy edge shared by the pills and the password box.
            readonly property color glassBorder: Qt.alpha(Colors.colors.foreground, 0.2)
            readonly property color glassFill: Qt.alpha(Colors.colors.surfaceInput, 0.6)

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
                blurMax: 120
                // Slightly richer and darker so the blur looks deliberate
                // rather than washed out.
                saturation: 0.15
                brightness: -0.05
                visible: screenshot.status === Image.Ready
            }

            // Theme tinted vignette: darker at the top and bottom edges where
            // the battery pill and slogan sit, lighter through the middle.
            Rectangle {
                anchors.fill: parent
                visible: screenshot.status === Image.Ready
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.alpha(Colors.colors.background, 0.55) }
                    GradientStop { position: 0.5; color: Qt.alpha(Colors.colors.background, 0.35) }
                    GradientStop { position: 1.0; color: Qt.alpha(Colors.colors.background, 0.65) }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Math.round(64 * lockSurface.u)

                opacity: lockSurface.shown ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(6 * lockSurface.u)

                    Rectangle {
                        id: timeBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: timeText.implicitWidth
                        Layout.preferredHeight: timeText.implicitHeight
                        color: "transparent"

                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: Time.time
                            color: Colors.colors.accent
                            font.pixelSize: Math.max(1, Math.round(120 * lockSurface.u))
                            font.family: Config.font
                            font.weight: Font.Light
                            font.letterSpacing: -Math.round(3 * lockSurface.u)
                        }
                    }

                    Rectangle {
                        id: userBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: userText.implicitWidth
                        Layout.preferredHeight: userText.implicitHeight
                        color: "transparent"

                        Text {
                            id: userText
                            anchors.centerIn: parent
                            text: Quickshell.env("USER")
                            color: Colors.colors.accent
                            font.pixelSize: Math.max(1, Math.round(30 * lockSurface.u))
                            font.family: Config.font
                            font.weight: Font.Medium
                            font.capitalization: Font.Capitalize
                            font.letterSpacing: Math.round(1 * lockSurface.u)
                        }
                    }

                    Rectangle {
                        id: langBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Math.round(6 * lockSurface.u)
                        Layout.preferredWidth: langText.implicitWidth + Math.round(28 * lockSurface.u)
                        Layout.preferredHeight: langText.implicitHeight + Math.round(12 * lockSurface.u)
                        radius: height / 2
                        color: Qt.alpha(Colors.colors.surfaceInput, 0.45)
                        border.width: 1
                        border.color: lockSurface.glassBorder

                        Text {
                            id: langText
                            anchors.centerIn: parent
                            text: Quickshell.env("LANG").slice(0, 2)
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: Math.max(1, Math.round(15 * lockSurface.u))
                            font.family: Config.font
                            font.weight: Font.DemiBold
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: Math.round(2 * lockSurface.u)
                        }
                    }

                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    Rectangle {
                        id: passwordBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.round(380 * lockSurface.u)
                        Layout.preferredHeight: Math.round(54 * lockSurface.u)
                        radius: height / 2
                        // Frosted glass, tinted red while an error is showing.
                        color: root.failed
                            ? Qt.alpha(Colors.colors.error, 0.14)
                            : lockSurface.glassFill
                        border.width: root.failed ? 2 : 1
                        border.color: root.failed
                            ? Colors.colors.error
                            : input.activeFocus
                                ? Colors.colors.borderActive
                                : lockSurface.glassBorder

                        // Use opacity rather than visible so the TextInput keeps
                        // keyboard focus while the box is hidden.
                        opacity: root.passwordVisible ? 1 : 0
                        scale: root.passwordVisible ? 1 : 0.96
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: passwordBox.height / 2
                            anchors.rightMargin: passwordBox.height / 2
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            visible: input.text.length === 0
                            text: pam.active ? "Checking..." : "Password"
                            color: Colors.colors.foregroundSubtle
                            font.pixelSize: Math.max(1, Math.round(17 * lockSurface.u))
                            font.family: Config.font
                            font.letterSpacing: Math.round(1 * lockSurface.u)
                        }

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: passwordBox.height / 2
                            anchors.rightMargin: passwordBox.height / 2
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: Colors.colors.foreground
                            selectionColor: Colors.colors.selected
                            selectedTextColor: Colors.colors.foreground
                            font.pixelSize: Math.max(1, Math.round(20 * lockSurface.u))
                            font.family: Config.font
                            font.letterSpacing: Math.round(4 * lockSurface.u)
                            clip: true
                            focus: true
                            enabled: !pam.active
                            // Dim the dots while the password is being checked.
                            opacity: pam.active ? 0.5 : 1
                            Behavior on opacity { NumberAnimation { duration: 150 } }

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
                        Layout.topMargin: Math.round(14 * lockSurface.u)
                        text: "Incorrect password"
                        color: Colors.colors.error
                        font.pixelSize: Math.max(1, Math.round(15 * lockSurface.u))
                        font.family: Config.font
                        font.weight: Font.Medium
                        font.letterSpacing: Math.round(0.5 * lockSurface.u)
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
                readonly property bool low: percent <= 20 && !charging
                readonly property real iconSize: Math.round(22 * lockSurface.u)

                // Pill styling matches the password box.
                readonly property real padX: Math.round(iconSize * 0.9)
                readonly property real padY: Math.round(iconSize * 0.5)

                x: Math.round(lockSurface.screenW * xFraction - width / 2)
                y: Math.round(56 * lockSurface.u)
                width: batteryRow.implicitWidth + padX * 2
                height: batteryRow.implicitHeight + padY * 2
                radius: height / 2
                color: low ? Qt.alpha(Colors.colors.error, 0.14) : lockSurface.glassFill
                border.width: 1
                border.color: low ? Qt.alpha(Colors.colors.error, 0.7) : lockSurface.glassBorder

                opacity: lockSurface.shown ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: batteryRow
                    anchors.centerIn: parent
                    spacing: Math.round(batteryBox.iconSize * 0.35)

                    Image {
                        visible: batteryBox.charging
                        Layout.preferredWidth: batteryBox.iconSize
                        Layout.preferredHeight: batteryBox.iconSize
                        fillMode: Image.PreserveAspectFit
                        source: Icons.getIcon("ui/electricBolt")
                        sourceSize.width: width
                        sourceSize.height: height
                    }

                    Image {
                        Layout.preferredWidth: batteryBox.iconSize
                        Layout.preferredHeight: batteryBox.iconSize
                        fillMode: Image.PreserveAspectFit
                        source: Icons.getIcon("heardware/laptop")
                        sourceSize.width: width
                        sourceSize.height: height
                    }

                    Text {
                        text: batteryBox.percent + "%"
                        color: batteryBox.low
                            ? Colors.colors.error
                            : batteryBox.charging
                                ? Colors.colors.success
                                : Colors.colors.foreground
                        font.pixelSize: Math.max(1, Math.round(batteryBox.iconSize * 0.85))
                        font.family: Config.font
                        font.weight: Font.Medium
                    }
                }
            }

            Rectangle {
                id: sloganBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(96 * lockSurface.u)
                width: sloganText.implicitWidth
                height: sloganText.implicitHeight
                color: "transparent"

                opacity: lockSurface.shown ? 0.85 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                }

                Text {
                    id: sloganText
                    anchors.centerIn: parent
                    text: "Keep Following The Strange Light"
                    color: Colors.colors.accentAlt
                    font.pixelSize: Math.max(1, Math.round(16 * lockSurface.u))
                    font.family: Config.font
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Math.round(4 * lockSurface.u)
                }
            }
        }
    }
}
