// qml/Bar/Brightness/BrightnessSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ----- Brightness -----
    // Desktops with no controllable backlight (external monitors with no
    // DDC/CI support) simply won't report a device here, so consumers
    // should hide brightness controls when this is false.
    property bool hasBacklight: false
    property int brightnessPercent: 0
    readonly property real brightnessValue: brightnessPercent / 100

    function refreshBrightness() {
        brightnessProbe.running = true
    }

    function setBrightness(v) {
        root.brightnessPercent = Math.round(Math.max(0, Math.min(1, v)) * 100)
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
                    root.hasBacklight = false
                    return
                }

                root.hasBacklight = true
                root.brightnessPercent = pct
            }
        }
    }

    // Debounce drag events so we don't spawn a brightnessctl process per
    // pixel of mouse movement.
    Timer {
        id: brightnessSetDebounce
        interval: 80
        onTriggered: {
            brightnessSetProcess.pendingPercent = root.brightnessPercent
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
        onTriggered: root.refreshBrightness()
    }

    // ----- Night Light (hyprsunset) -----
    readonly property int minKelvin: 2500
    readonly property int maxKelvin: 6500

    property bool nightlightEnabled: false
    property real nightlightWarmth: 0.5 // 0 = coolest (off-like), 1 = warmest
    readonly property int currentKelvin: Math.round(maxKelvin - nightlightWarmth * (maxKelvin - minKelvin))

    function toggleNightlight() {
        root.nightlightEnabled = !root.nightlightEnabled
        applyNightlight()
    }

    function setNightlightWarmth(v) {
        root.nightlightWarmth = Math.max(0, Math.min(1, v))
        if (root.nightlightEnabled)
            nightlightSetDebounce.restart()
    }

    function applyNightlight() {
        if (root.nightlightEnabled) {
            nightlightSetProcess.kelvin = root.currentKelvin
            nightlightSetProcess.running = true
        } else {
            nightlightResetProcess.running = true
        }
    }

    Timer {
        id: nightlightSetDebounce
        interval: 80
        onTriggered: {
            nightlightSetProcess.kelvin = root.currentKelvin
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
}
