// qml/Bar/Network/NetworkPopup.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import "../../Components"
import "../../Colors"

BarPopup {
    id: networkPopup

    signal requestClose()

    // ----- Status -----
    property string connectionType: "none"   // "ethernet" | "wifi" | "none"
    property string wifiDevice: ""
    property string ethernetConnectionName: ""
    property string activeSsid: ""
    property bool wifiRadioOn: true
    property bool busy: false

    // ----- Wifi list -----
    property var networks: []

    // ----- Inline connect form -----
    property string connectingSsid: ""
    property string passwordInput: ""
    property string statusMessage: ""

    readonly property bool showingConnectForm: connectingSsid.length > 0

    function resetSelection() {
        networkPopup.statusMessage = ""
        networkPopup.connectingSsid = ""
        networkPopup.passwordInput = ""
    }

    function closePopup() {
        networkPopup.requestClose()
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

    function refreshAll() {
        statusProc.running = true
        radioProc.running = true
        refreshWifiList()
    }

    function refreshWifiList() {
        wifiListProc.running = true
    }

    function rescan() {
        networkPopup.busy = true
        rescanProc.running = true
    }

    function toggleWifiRadio() {
        radioToggleProc.command = ["nmcli", "radio", "wifi", networkPopup.wifiRadioOn ? "off" : "on"]
        radioToggleProc.running = true
    }

    function beginConnect(ssid) {
        networkPopup.statusMessage = ""
        networkPopup.passwordInput = ""
        networkPopup.connectingSsid = ssid
    }

    function cancelConnect() {
        networkPopup.connectingSsid = ""
        networkPopup.passwordInput = ""
    }

    function connectOpen(ssid) {
        networkPopup.statusMessage = ""
        connectProc.ssid = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function submitConnect() {
        const ssid = networkPopup.connectingSsid
        connectProc.ssid = ssid
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", networkPopup.passwordInput]
        connectProc.running = true
    }

    function disconnectCurrent() {
        if (networkPopup.wifiDevice.length === 0)
            return
        disconnectProc.command = ["nmcli", "device", "disconnect", networkPopup.wifiDevice]
        disconnectProc.running = true
    }

    // ----- Backing processes -----

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
                    const f = networkPopup.splitNmcli(raw)
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

                networkPopup.wifiDevice = wifiDev
                networkPopup.ethernetConnectionName = ethernetName
                networkPopup.activeSsid = wifiConnected ? wifiName : ""
                networkPopup.connectionType = ethernetConnected ? "ethernet" : (wifiConnected ? "wifi" : "none")
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkPopup.wifiRadioOn = this.text.trim().toLowerCase().startsWith("enabled")
            }
        }
    }

    Process {
        id: radioToggleProc
        onExited: {
            radioProc.running = true
            networkPopup.refreshWifiList()
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
                    const f = networkPopup.splitNmcli(raw)
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

                networkPopup.networks = list
                networkPopup.busy = false
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
        onTriggered: networkPopup.refreshWifiList()
    }

    Process {
        id: connectProc
        property string ssid: ""
        onExited: (exitCode) => {
            if (exitCode === 0) {
                networkPopup.statusMessage = ""
                networkPopup.connectingSsid = ""
                networkPopup.passwordInput = ""
            } else {
                networkPopup.statusMessage = "Couldn't connect to " + connectProc.ssid + ". Check the password and try again."
            }
            networkPopup.refreshAll()
        }
    }

    Process {
        id: disconnectProc
        onExited: networkPopup.refreshAll()
    }

    Keys.onEscapePressed: {
        if (networkPopup.showingConnectForm)
            networkPopup.cancelConnect()
        else
            networkPopup.closePopup()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ----- Status card -----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 8
            color: Colors.colors.surfaceAlt
            border.width: 1
            border.color: Colors.colors.borderSoft

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: networkPopup.connectionType === "ethernet" ? "\udb80\ude01"
                        : networkPopup.connectionType === "wifi" ? "\uf1eb"
                        : "\uf1eb"
                    color: networkPopup.connectionType === "none" ? Colors.colors.foregroundMuted : Colors.colors.success
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: networkPopup.connectionType === "ethernet" ? "Ethernet"
                            : networkPopup.connectionType === "wifi" ? "Wi-Fi"
                            : "Not connected"
                        color: Colors.colors.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: networkPopup.connectionType === "ethernet" ? networkPopup.ethernetConnectionName
                            : networkPopup.connectionType === "wifi" ? networkPopup.activeSsid
                            : "No active connection"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: "\uf021"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: networkPopup.refreshAll()
                    }
                }
            }
        }

        // ----- Wi-Fi toggle + rescan row -----
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 8

            RowLayout {
                spacing: 6

                Rectangle {
                    id: toggleTrack
                    implicitWidth: 34
                    implicitHeight: 18
                    radius: height / 2
                    color: networkPopup.wifiRadioOn ? Colors.colors.accent : Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: networkPopup.wifiRadioOn ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Colors.colors.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: networkPopup.wifiRadioOn ? parent.width - width - 2 : 2

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: networkPopup.toggleWifiRadio()
                    }
                }

                Text {
                    text: "Wi-Fi"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: rescanButton
                implicitHeight: 22
                implicitWidth: rescanLabel.implicitWidth + 16
                radius: 6
                visible: networkPopup.wifiRadioOn
                color: rescanHover.hovered ? Colors.colors.surfaceAlt : "transparent"
                border.width: 1
                border.color: Colors.colors.borderSoft

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: rescanLabel
                    anchors.centerIn: parent
                    text: networkPopup.busy ? "Scanning..." : "Rescan"
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 11
                }

                HoverHandler { id: rescanHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: networkPopup.rescan()
                }
            }
        }

        // ----- Connect form (overlays the list while active) -----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            visible: networkPopup.showingConnectForm
            radius: 8
            color: Colors.colors.surface
            border.width: 1
            border.color: Colors.colors.borderSoft

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "Connect to " + networkPopup.connectingSsid
                    color: Colors.colors.foreground
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 8
                    color: Colors.colors.surfaceAlt
                    border.width: 1
                    border.color: passwordField.activeFocus ? Colors.colors.accent : Colors.colors.borderSoft

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colors.colors.foreground
                        font.pixelSize: 12
                        echoMode: TextInput.Password
                        clip: true
                        selectByMouse: true
                        focus: networkPopup.showingConnectForm

                        onTextChanged: networkPopup.passwordInput = text
                        Keys.onReturnPressed: networkPopup.submitConnect()
                        Keys.onEnterPressed: networkPopup.submitConnect()
                        Keys.onEscapePressed: networkPopup.cancelConnect()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: 64
                        radius: 6
                        color: "transparent"
                        border.width: 1
                        border.color: Colors.colors.borderSoft

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: networkPopup.cancelConnect()
                        }
                    }

                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: 74
                        radius: 6
                        color: Colors.colors.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Colors.colors.foreground
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: networkPopup.submitConnect()
                        }
                    }
                }
            }
        }

        // ----- Network list -----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !networkPopup.showingConnectForm

            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true

                ListView {
                    id: listView
                    width: scrollView.width
                    model: networkPopup.wifiRadioOn ? networkPopup.networks : []
                    spacing: 4

                    delegate: Rectangle {
                        id: entryDelegate
                        required property var modelData
                        required property int index

                        width: listView.width
                        height: 38
                        radius: 6
                        color: itemHover.hovered ? Colors.colors.hover : Colors.colors.surface

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: itemHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: entryDelegate.modelData.signal >= 70 ? "\uf1eb"
                                    : entryDelegate.modelData.signal >= 40 ? "\uf1eb"
                                    : "\uf1eb"
                                color: entryDelegate.modelData.inUse ? Colors.colors.success : Colors.colors.foregroundMuted
                                font.pixelSize: 14
                                opacity: Math.max(0.35, entryDelegate.modelData.signal / 100)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entryDelegate.modelData.ssid
                                color: Colors.colors.foreground
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                visible: entryDelegate.modelData.secured
                                text: "\uf023"
                                color: Colors.colors.foregroundMuted
                                font.pixelSize: 11
                            }

                            Rectangle {
                                visible: entryDelegate.modelData.inUse
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: disconnectHover.hovered ? Colors.colors.error : "transparent"

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 11
                                    color: disconnectHover.hovered ? Colors.colors.background : Colors.colors.foregroundMuted
                                }

                                HoverHandler { id: disconnectHover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: networkPopup.disconnectCurrent()
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: entryDelegate.modelData.inUse ? 28 : 0
                            cursorShape: entryDelegate.modelData.inUse ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled: !entryDelegate.modelData.inUse
                            onClicked: {
                                if (entryDelegate.modelData.secured)
                                    networkPopup.beginConnect(entryDelegate.modelData.ssid)
                                else
                                    networkPopup.connectOpen(entryDelegate.modelData.ssid)
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: networkPopup.wifiRadioOn && networkPopup.networks.length === 0
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                text: "No networks found"
            }

            Text {
                anchors.centerIn: parent
                visible: !networkPopup.wifiRadioOn
                color: Colors.colors.foregroundMuted
                font.pixelSize: 12
                text: "Wi-Fi is off"
            }
        }

        // ----- Error / status message -----
        Text {
            Layout.fillWidth: true
            visible: networkPopup.statusMessage.length > 0
            text: networkPopup.statusMessage
            color: Colors.colors.error
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }
}
