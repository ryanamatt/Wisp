// qml/Bar/Network/NetworkSingleton.qml

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ----- Shared state (was previously duplicated per-monitor across
    // NetworkWidget's status poll and each NetworkPopup instance) -----

    property string connectionType: "none" // "ethernet" | "wifi" | "none"
    property string wifiDevice: ""
    property string ethernetConnectionName: ""
    property string activeSsid: ""
    property bool wifiRadioOn: true
    property bool busy: false
    property var networks: []
    property string statusMessage: ""

    // Emitted after a connect attempt so any open popup's inline form knows
    // whether to close (success) or stay open showing statusMessage (failure).
    signal connectResult(bool success, string ssid)

    // ----- Public API -----

    function refreshAll() {
        refreshStatus()
        radioProc.running = true
        refreshWifiList()
    }

    function refreshStatus() {
        statusProc.running = true
    }

    function refreshWifiList() {
        wifiListProc.running = true
    }

    function rescan() {
        root.busy = true
        rescanProc.running = true
    }

    function toggleWifiRadio() {
        radioToggleProc.command = ["nmcli", "radio", "wifi", root.wifiRadioOn ? "off" : "on"]
        radioToggleProc.running = true
    }

    function connectOpen(ssid) {
        root.statusMessage = ""
        connectProc.ssid = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function connectWithPassword(ssid, password) {
        root.statusMessage = ""
        connectProc.ssid = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        connectProc.running = true
    }

    function disconnectCurrent() {
        if (root.wifiDevice.length === 0)
            return
        disconnectProc.command = ["nmcli", "device", "disconnect", root.wifiDevice]
        disconnectProc.running = true
    }

    // nmcli -t output escapes literal ':' inside a field as '\:'. Split by
    // hand instead of a naive line.split(":") so SSIDs/names with colons
    // survive intact.
    function splitNmcli(line) {
        const fields = []
        let current = ""
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length) {
                current += line[i + 1]
                i++
            } else if (ch === ":") {
                fields.push(current)
                current = ""
            } else {
                current += ch
            }
        }
        fields.push(current)
        return fields
    }

    // ----- Backing processes (single instance, shared across all screens) -----

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ethernetConnected = false
                let ethernetName = ""
                let wifiDev = ""
                let wifiConnected = false
                let wifiName = ""

                for (const raw of this.text.split("\n")) {
                    if (raw.length === 0) continue
                    const f = root.splitNmcli(raw)
                    if (f.length < 4) continue
                    const [device, type, state, connection] = f

                    if (type === "ethernet" && state === "connected") {
                        ethernetConnected = true
                        ethernetName = connection
                    }
                    if (type === "wifi") {
                        wifiDev = device
                        if (state === "connected") {
                            wifiConnected = true
                            wifiName = connection
                        }
                    }
                }

                root.wifiDevice = wifiDev
                root.ethernetConnectionName = ethernetName
                root.activeSsid = wifiConnected ? wifiName : ""
                root.connectionType = ethernetConnected ? "ethernet" : (wifiConnected ? "wifi" : "none")
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiRadioOn = this.text.trim().toLowerCase().startsWith("enabled")
            }
        }
    }

    Process {
        id: radioToggleProc
        onExited: {
            radioProc.running = true
            root.refreshWifiList()
        }
    }

    Process {
        id: wifiListProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set()
                const list = []

                for (const raw of this.text.split("\n")) {
                    if (raw.length === 0) continue
                    const f = root.splitNmcli(raw)
                    if (f.length < 4) continue

                    const inUse = f[0].trim() === "*"
                    const signal = parseInt(f[1], 10) || 0
                    const security = f[2]
                    const ssid = f.slice(3).join(":")

                    if (ssid.length === 0) continue
                    if (seen.has(ssid)) continue
                    seen.add(ssid)

                    list.push({
                        ssid: ssid,
                        signal: signal,
                        secured: security.length > 0 && security !== "--",
                        inUse: inUse
                    })
                }

                list.sort((a, b) => {
                    if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                    return b.signal - a.signal
                })

                root.networks = list
                root.busy = false
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: rescanTimer.start()
    }

    // Rescan needs a beat before the results settle.
    Timer {
        id: rescanTimer
        interval: 1500
        onTriggered: root.refreshWifiList()
    }

    Process {
        id: connectProc
        property string ssid: ""
        onExited: (exitCode) => {
            const success = exitCode === 0
            root.statusMessage = success ? "" : ("Couldn't connect to " + connectProc.ssid + ". Check the password and try again.")
            root.connectResult(success, connectProc.ssid)
            root.refreshAll()
        }
    }

    Process {
        id: disconnectProc
        onExited: root.refreshAll()
    }

    // Lightweight status poll so the bar icon on every screen stays accurate
    // even while no popup is open. Runs once, centrally, instead of once
    // per monitor.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }
}
