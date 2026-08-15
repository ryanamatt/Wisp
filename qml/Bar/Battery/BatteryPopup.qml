// qml/Bar/Battery/BatteryPopup.qml

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"

BarPopup {
    id: batteryPopup

    signal requestClose()

    Keys.onEscapePressed: batteryPopup.requestClose()

    readonly property string systemIcon: "\uf109"   // laptop
    readonly property string razerIcon: "\uf11b"     // gamepad (stand-in for Razer peripherals)
    readonly property string headsetIcon: "\uf025"   // headphones
    readonly property string bluetoothIcon: "\uf293" // bluetooth

    property var systemBatteryList: []
    property var razerList: []
    property var headsetList: []
    property var bluetoothList: []

    // Bluetooth devices that headsetcontrol already reported get dropped
    // here so a headset connected over BT doesn't show up twice.
    readonly property var accessories: {
        const dedupedBluetooth = batteryPopup.bluetoothList.filter(bt => {
            return !batteryPopup.headsetList.some(hs => hs.name.toLowerCase() === bt.name.toLowerCase())
        })
        return batteryPopup.systemBatteryList
            .concat(batteryPopup.razerList)
            .concat(batteryPopup.headsetList)
            .concat(dedupedBluetooth)
    }

    function refreshAll() {
        systemBatteryProbe.running = true
        razerProbe.running = true
        headsetProbe.running = true
        bluetoothProbe.running = true
    }

    // Battery percentages don't change fast, so a slow poll is enough to
    // stay current while the popup sits closed.
    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryPopup.refreshAll()
    }

    // ----- System battery -----
    Process {
        id: systemBatteryProbe
        command: ["bash", "-c",
            "for b in /sys/class/power_supply/BAT*; do " +
            "if [ -f $b/capacity ]; then " +
            "echo $(cat $b/capacity 2>/dev/null),$(cat $b/status 2>/dev/null); " +
            "break; fi; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (line.length === 0) {
                    batteryPopup.systemBatteryList = []
                    return
                }
                const parts = line.split(",")
                const pct = parseInt(parts[0], 10)
                if (isNaN(pct)) {
                    batteryPopup.systemBatteryList = []
                    return
                }
                const status = (parts[1] || "").trim()
                batteryPopup.systemBatteryList = [{
                    name: "Laptop Battery",
                    percent: pct,
                    icon: batteryPopup.systemIcon,
                    charging: status === "Charging"
                }]
            }
        }
    }

    // ----- Razer peripherals -----
    function parseRazerList(text) {
        try {
            const lines = text.split(/\r?\n/)
            const devices = []
            let current = null
            let inBattery = false
            let batteryIndent = -1

            for (const raw of lines) {
                if (raw.trim().length === 0)
                    continue

                // Regex-based indent detection (avoids String.trimStart(),
                // which isn't available in every QML JS engine).
                const indentMatch = raw.match(/^[ \t]*/)
                const indent = indentMatch ? indentMatch[0].length : 0
                const trimmed = raw.trim()

                // Device headers sit at column 0, e.g.
                // "Razer DeathAdder V2 Pro (Wireless):"
                if (indent === 0) {
                    if (trimmed.indexOf("Razer") === 0 && trimmed.charAt(trimmed.length - 1) === ":") {
                        current = { name: trimmed.slice(0, -1), charge: null, charging: false }
                        devices.push(current)
                    } else {
                        current = null
                    }
                    inBattery = false
                    batteryIndent = -1
                    continue
                }

                if (!current)
                    continue

                if (trimmed === "battery:") {
                    inBattery = true
                    batteryIndent = indent
                    continue
                }

                if (inBattery && indent <= batteryIndent) {
                    inBattery = false
                    batteryIndent = -1
                }

                if (inBattery) {
                    const chargeMatch = trimmed.match(/charge:\s*(\d+)/)
                    if (chargeMatch)
                        current.charge = parseInt(chargeMatch[1], 10)

                    const chargingMatch = trimmed.match(/charging:\s*(true|false)/i)
                    if (chargingMatch)
                        current.charging = chargingMatch[1].toLowerCase() === "true"
                }
            }

            return devices
                .filter(d => d.charge !== null && !isNaN(d.charge))
                .map(d => ({
                    name: d.name,
                    percent: d.charge,
                    icon: batteryPopup.razerIcon,
                    charging: d.charging
                }))
        } catch (e) {
            return []
        }
    }

    Process {
        id: razerProbe
        command: ["bash", "-c", "razer-cli -l 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                batteryPopup.razerList = batteryPopup.parseRazerList(this.text)
            }
        }
    }

    // ----- Headset (SteelSeries/Corsair/Logitech/etc via headsetcontrol) -----
    Process {
        id: headsetProbe
        command: ["bash", "-c", "headsetcontrol -o json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)
                    const devices = data.devices || []
                    batteryPopup.headsetList = devices
                        .filter(dev => dev.battery && typeof dev.battery.level === "number" && dev.battery.status !== "BATTERY_UNAVAILABLE")
                        .map(dev => ({
                            name: dev.device,
                            percent: dev.battery.level,
                            icon: batteryPopup.headsetIcon,
                            charging: dev.battery.status === "BATTERY_CHARGING"
                        }))
                } catch (e) {
                    batteryPopup.headsetList = []
                }
            }
        }
    }

    // ----- Generic Bluetooth accessories -----
    Process {
        id: bluetoothProbe
        command: ["bash", "-c",
            "for mac in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do " +
            "info=$(bluetoothctl info \"$mac\" 2>/dev/null); " +
            "name=$(echo \"$info\" | grep 'Alias:' | head -n1 | cut -d' ' -f2-); " +
            "batt=$(echo \"$info\" | grep 'Battery Percentage' | grep -oE '\\([0-9]+\\)' | tr -d '()'); " +
            "if [ -n \"$batt\" ] && [ -n \"$name\" ]; then echo \"$name|$batt\"; fi; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0)
                batteryPopup.bluetoothList = lines.map(line => {
                    const parts = line.split("|")
                    return {
                        name: parts[0],
                        percent: parseInt(parts[1], 10),
                        icon: batteryPopup.bluetoothIcon,
                        charging: false
                    }
                }).filter(d => !isNaN(d.percent))
            }
        }
    }

    Component.onCompleted: refreshAll()

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Battery & Accessories"
            color: Colors.colors.foreground
            font.family: "Noto Sans Mono"
            font.pixelSize: 13
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: batteryPopup.accessories.length > 0

            Repeater {
                model: batteryPopup.accessories

                delegate: RowLayout {
                    id: row
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: row.modelData.icon
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 16
                        color: row.modelData.charging ? Colors.colors.accentAlt : Colors.colors.foreground
                        Layout.preferredWidth: 20
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        color: Colors.colors.foreground
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Colors.colors.surface

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(3, parent.width * Math.max(0, Math.min(100, row.modelData.percent)) / 100)
                            height: 6
                            radius: 3
                            color: row.modelData.percent <= 20
                                ? Colors.colors.error
                                : (row.modelData.charging ? Colors.colors.accentAlt : Colors.colors.accent)
                        }
                    }

                    Text {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: row.modelData.percent + "%"
                        color: row.modelData.percent <= 20 ? Colors.colors.error : Colors.colors.foregroundMuted
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 12
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: batteryPopup.accessories.length === 0
            text: "No battery-reporting devices found"
            horizontalAlignment: Text.AlignHCenter
            color: Colors.colors.foregroundMuted
            font.family: "Noto Sans Mono"
            font.pixelSize: 12
        }
    }
}
