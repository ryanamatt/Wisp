// qml/Bar/Network/NetworkWidget.qml

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../Components"
import "../../GlobalState"
import "../../Colors"

BarWidgetContainer {
    id: networkWidget

    required property var screen

    implicitWidth: 50

    // Polled independently of the popup so the bar icon stays accurate
    // even while the popup is closed.
    property string connectionType: "none" // "ethernet" | "wifi" | "none"

    icon.text: connectionType === "ethernet" ? "\udb80\ude01" : "\uf1eb"
    icon.color: connectionType === "none" ? Colors.colors.foregroundMuted : Colors.colors.foreground

    isOpenHere: GlobalState.networkWidget.isOpenOn(networkWidget.screen)

    popupWindows: [networkPopupWindow]

    onRequestOpen: GlobalState.networkWidget.open(networkWidget.screen)
    onRequestClose: GlobalState.networkWidget.close()

    onIsOpenHereChanged: {
        if (isOpenHere) {
            popup.resetSelection()
            popup.forceActiveFocus()
            popup.refreshAll()
            activateFocusGrab()
        } else {
            popup.closePopup()
            releaseFocusGrab()
        }
    }

    // Lightweight status poll, independent from the popup's own (more
    // detailed) refresh so the pill icon reflects reality at a glance.
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

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusPollProc.running = true
    }

    Process {
        id: statusPollProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ethernetConnected = false
                let wifiConnected = false

                for (const raw of this.text.split("\n")) {
                    if (raw.length === 0) continue
                    const f = networkWidget.splitNmcli(raw)
                    if (f.length < 2) continue
                    const [type, state] = f

                    if (type === "ethernet" && state === "connected") ethernetConnected = true
                    if (type === "wifi" && state === "connected") wifiConnected = true
                }

                networkWidget.connectionType = ethernetConnected ? "ethernet" : (wifiConnected ? "wifi" : "none")
            }
        }
    }

    PopupWindow {
        id: networkPopupWindow

        anchor.item: networkWidget
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.HCenter
        anchor.margins.top: 0

        color: "transparent"

        implicitHeight: 300
        implicitWidth: 300

        visible: networkWidget.openProgress > 0.001 || networkWidget.isOpenHere

        Item {
            anchors.fill: parent

            Rectangle {
                id: panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height

                transformOrigin: Item.Top
                scale: 0.85 + 0.15 * networkWidget.openProgress
                opacity: networkWidget.openProgress
                y: (1 - networkWidget.openProgress) * -14
                radius: 20

                color: Colors.colors.backgroundAlt
                border.color: Colors.colors.background
                border.width: 2

                HoverHandler {
                    id: popupHover
                    onHoveredChanged: {
                        if (popupHover.hovered) {
                            networkWidget.open()
                        } else {
                            networkWidget.close()
                        }
                    }
                }

                NetworkPopup {
                    id: popup
                    anchors.fill: parent
                    anchors.margins: 10

                    opacity: Math.max(0, (networkWidget.openProgress - 0.25) / 0.75)

                    onRequestClose: networkWidget.forceClose()
                }
            }
        }
    }
}
