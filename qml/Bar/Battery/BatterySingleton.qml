// qml/Bar/Battery/BatterySingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../Config"

Singleton {
    id: root

    readonly property string systemIcon: "laptop"
    readonly property string razerIcon: "mouse"
    readonly property string headsetIcon: "headphones"
    readonly property string bluetoothIcon: "bluetooth"

    property var systemBatteryList: []
    property var razerList: []
    property var headsetList: []
    property var bluetoothList: []

    // Bluetooth devices that headsetcontrol already reported get dropped
    // here so a headset connected over BT doesn't show up twice.
    readonly property var accessories: {
        const dedupedBluetooth = root.bluetoothList.filter(bt => {
            return !root.headsetList.some(hs => hs.name.toLowerCase() === bt.name.toLowerCase())
        })
        return root.systemBatteryList
            .concat(root.razerList)
            .concat(root.headsetList)
            .concat(dedupedBluetooth)
    }

    function refreshAll() {
        systemBatteryProbe.running = true
        razerProbe.running = true
        headsetProbe.running = true
        bluetoothProbe.running = true
        checkNotify()
    }

    // Battery percentages don't change fast, so a slow poll is enough to
    // stay current while the popup sits closed.
    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
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
                    root.systemBatteryList = []
                    return
                }
                const parts = line.split(",")
                const pct = parseInt(parts[0], 10)
                if (isNaN(pct)) {
                    root.systemBatteryList = []
                    return
                }
                const status = (parts[1] || "").trim()
                root.systemBatteryList = [{
                    name: "Laptop Battery",
                    percent: pct,
                    icon: root.systemIcon,
                    charging: status === "Charging",
                    sentLowNotif: false
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
                    icon: root.razerIcon,
                    charging: d.charging,
                    sentLowNotif: false
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
                root.razerList = root.parseRazerList(this.text)
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
                    root.headsetList = devices
                        .filter(dev => dev.battery && typeof dev.battery.level === "number" && dev.battery.status !== "BATTERY_UNAVAILABLE")
                        .map(dev => ({
                            name: dev.device,
                            percent: dev.battery.level,
                            icon: root.headsetIcon,
                            charging: dev.battery.status === "BATTERY_CHARGING",
                            sentLowNotif: false
                        }))
                } catch (e) {
                    root.headsetList = []
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
                root.bluetoothList = lines.map(line => {
                    const parts = line.split("|")
                    return {
                        name: parts[0],
                        percent: parseInt(parts[1], 10),
                        icon: root.bluetoothIcon,
                        charging: false,
                        sentLowNotif: false
                    }
                }).filter(d => !isNaN(d.percent))
            }
        }
    }

    function checkNotify() {
        let updateList = (list) => {
            return list.map(dev => {
                let sentLowNotif = dev.sentLowNotif || false;

                if (!dev.charging && !sentLowNotif && dev.percent <= Config.batteryWarnPerc) {
                    sentLowNotif = true;
                    sendNotification(dev.name, dev.percent);
                } else if (dev.charging && sentLowNotif && dev.percent > Config.batteryWarnPerc) {
                    sentLowNotif = false;
                }

                return {
                    name: dev.name,
                    percent: dev.percent,
                    icon: dev.icon,
                    charging: dev.charging,
                    sentLowNotif: sentLowNotif
                };
            });
        }

        root.systemBatteryList = updateList(root.systemBatteryList);
        root.razerList = updateList(root.razerList);
        root.headsetList = updateList(root.headsetList);
        root.bluetoothList = updateList(root.bluetoothList);

    }

    function sendNotification(batteryName, batteryPercent) {
        let description = batteryName + " at " + batteryPercent + "%"
        let com = ["notify-send", "Low Battery", description]
        sendBatteryNotification.command = com
        sendBatteryNotification.running = true
    }

    Process {
        id: sendBatteryNotification
    }
}
