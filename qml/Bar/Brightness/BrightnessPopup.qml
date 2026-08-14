// qml/Bar/Brightness/BrightnessPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"

BarPopup {
    id: brightnessPopup

    signal requestClose()

    Keys.onEscapePressed: brightnessPopup.requestClose()

    // Desktops with no controllable backlight (external monitors with no
    // DDC/CI support) simply won't report a device here, so the slider
    // hides itself instead of controlling nothing.
    property bool hasBacklight: false
    property int brightnessPercent: 0
    readonly property real brightnessValue: brightnessPercent / 100

    function refreshBrightness() {
        brightnessProbe.running = true
    }

    function setBrightness(v) {
        brightnessPopup.brightnessPercent = Math.round(Math.max(0, Math.min(1, v)) * 100)
        brightnessSetDebounce.restart()
    }

    Process {
        id: brightnessProbe
        // brightnessctl -m prints: device,class,current,percent%,max
        command: ["bash", "-c", "brightnessctl -m 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                const fields = line.split(",")
                const pct = fields.length >= 4 ? parseInt(fields[3], 10) : NaN

                if (line.length === 0 || isNaN(pct)) {
                    brightnessPopup.hasBacklight = false
                    return
                }

                brightnessPopup.hasBacklight = true
                brightnessPopup.brightnessPercent = pct
            }
        }
    }

    // Debounce drag events so we don't spawn a brightnessctl process per
    // pixel of mouse movement.
    Timer {
        id: brightnessSetDebounce
        interval: 80
        onTriggered: {
            brightnessSetProcess.pendingPercent = brightnessPopup.brightnessPercent
            brightnessSetProcess.running = true
        }
    }

    Process {
        id: brightnessSetProcess
        property int pendingPercent: 50
        command: ["brightnessctl", "set", pendingPercent + "%"]
    }

    // brightnessctl has no watch mode, so poll occasionally to stay in
    // sync with hardware keys / other tools changing the backlight.
    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: brightnessPopup.refreshBrightness()
    }

    // Night Light (hyprsunset)
    readonly property int minKelvin: 2500
    readonly property int maxKelvin: 6500

    property bool nightlightEnabled: false
    property real nightlightWarmth: 0.5 // 0 = coolest (off-like), 1 = warmest
    readonly property int currentKelvin: Math.round(maxKelvin - nightlightWarmth * (maxKelvin - minKelvin))

    function toggleNightlight() {
        brightnessPopup.nightlightEnabled = !brightnessPopup.nightlightEnabled
        applyNightlight()
    }

    function setNightlightWarmth(v) {
        brightnessPopup.nightlightWarmth = Math.max(0, Math.min(1, v))
        if (brightnessPopup.nightlightEnabled)
            nightlightSetDebounce.restart()
    }

    function applyNightlight() {
        if (brightnessPopup.nightlightEnabled) {
            nightlightSetProcess.kelvin = brightnessPopup.currentKelvin
            nightlightSetProcess.running = true
        } else {
            nightlightResetProcess.running = true
        }
    }

    Timer {
        id: nightlightSetDebounce
        interval: 80
        onTriggered: {
            nightlightSetProcess.kelvin = brightnessPopup.currentKelvin
            nightlightSetProcess.running = true
        }
    }

    Process {
        id: nightlightSetProcess
        property int kelvin: 4500
        command: ["hyprctl", "hyprsunset", "temperature", kelvin.toString()]
    }

    Process {
        id: nightlightResetProcess
        command: ["hyprctl", "hyprsunset", "identity"]
    }

    Component.onCompleted: refreshBrightness()

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 14

        // ----- Brightness -----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: brightnessPopup.hasBacklight

            Text {
                text: "\uf185"
                font.family: "Iosevka Nerd Font Propo"
                font.pixelSize: 18
                color: Colors.colors.foreground

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: brightnessPopup.setBrightness(1)
                }
            }

            DragBar {
                Layout.fillWidth: true
                enabled: brightnessPopup.hasBacklight
                value: brightnessPopup.brightnessValue
                onMoved: v => brightnessPopup.setBrightness(v)
            }

            Text {
                Layout.preferredWidth: 34
                text: brightnessPopup.brightnessPercent + "%"
                color: Colors.colors.foregroundMuted
                font.family: "Noto Sans Mono"
                font.pixelSize: 12
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !brightnessPopup.hasBacklight
            text: "No backlight on this display"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: "Noto Sans Mono"
            font.pixelSize: 12
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        // ----- Night Light -----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "\uf186"
                    font.family: "Iosevka Nerd Font Propo"
                    font.pixelSize: 16
                    color: brightnessPopup.nightlightEnabled ? Colors.colors.accentAlt : Colors.colors.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: "Night Light"
                    color: Colors.colors.foreground
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 13
                }

                Rectangle {
                    id: nightlightToggleTrack
                    implicitWidth: 34
                    implicitHeight: 18
                    radius: height / 2
                    color: brightnessPopup.nightlightEnabled ? Colors.colors.accent : Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: brightnessPopup.nightlightEnabled ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: brightnessPopup.nightlightEnabled ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: brightnessPopup.toggleNightlight()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: brightnessPopup.nightlightEnabled

                Text {
                    text: "Warmth"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 11
                }

                DragBar {
                    Layout.fillWidth: true
                    enabled: brightnessPopup.nightlightEnabled
                    fillColor: Colors.colors.accentAlt
                    value: brightnessPopup.nightlightWarmth
                    onMoved: v => brightnessPopup.setNightlightWarmth(v)
                }

                Text {
                    Layout.preferredWidth: 48
                    text: brightnessPopup.currentKelvin + "K"
                    color: Colors.colors.foregroundMuted
                    font.family: "Noto Sans Mono"
                    font.pixelSize: 12
                }
            }
        }
    }
}
