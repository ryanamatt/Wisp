// qml/WindowRules/WindowRules.qml

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../Colors"
import "../Icons"
import "../IpcState"
import "../Config"

FloatingWindow {
    id: win

    // "Wisp" in the title makes the Hyprland config float this window
    title: "Wisp Window Rules"

    implicitWidth: 460
    implicitHeight: 620
    minimumSize: Qt.size(340, 300)

    color: "transparent"

    // Starts closed by default, opens only when IPC command triggers it
    visible: IpcState.windowRules.isOpen

    // The client currently being inspected (raw object from hyprctl clients -j)
    property var client: null
    // Display model built from the client: [{ name, icon, rows: [{ key, text, kind }] }]
    property var sections: []
    property string errorText: ""
    property bool needsRerun: false

    // Which JSON keys go in which section. Any key not listed here
    // ends up in an "Other" section, so nothing from the JSON is hidden.
    readonly property var sectionLayout: [
        {
            name: "Identity", icon: "ui/badge",
            keys: ["class", "initialClass", "title", "initialTitle", "tags", "xdgTag", "xdgDescription"]
        },
        {
            name: "Process", icon: "hardware/memory",
            keys: ["pid", "address", "stableId", "xwayland"]
        },
        {
            name: "Geometry", icon: "ui/aspectRatio",
            keys: ["at", "size"]
        },
        {
            name: "Placement", icon: "ui/workspaces",
            keys: ["workspace", "monitor"]
        },
        {
            name: "State", icon: "ui/toggleOn",
            keys: ["floating", "pinned", "fullscreen", "fullscreenClient", "pseudo", "mapped", "hidden",
                   "grouped", "swallowing", "inhibitingIdle", "contentType", "focusHistoryID"]
        }
    ]

    function formatValue(key, v) {
        if (v === null || v === undefined)
            return { text: "(none)", kind: "empty" }
        if (typeof v === "boolean")
            return { text: v ? "true" : "false", kind: v ? "on" : "off" }
        if (typeof v === "string")
            return v === "" ? { text: "(empty)", kind: "empty" } : { text: v, kind: "text" }
        if (typeof v === "number")
            return { text: String(v), kind: "text" }
        if (Array.isArray(v)) {
            if (v.length === 0)
                return { text: "(empty)", kind: "empty" }
            if (key === "at" && v.length === 2)
                return { text: v[0] + ", " + v[1], kind: "text" }
            if (key === "size" && v.length === 2)
                return { text: v[0] + " x " + v[1], kind: "text" }
            return {
                text: v.map(x => typeof x === "object" ? JSON.stringify(x) : String(x)).join(", "),
                kind: "text"
            }
        }
        if (key === "workspace" && v.name !== undefined)
            return { text: v.name + " (id " + v.id + ")", kind: "text" }
        return { text: JSON.stringify(v), kind: "text" }
    }

    function buildSections(c) {
        if (!c)
            return []

        const used = ({})
        const out = []

        for (const def of sectionLayout) {
            const rows = []
            for (const k of def.keys) {
                if (!(k in c))
                    continue
                used[k] = true
                rows.push(Object.assign({ key: k }, formatValue(k, c[k])))
            }
            if (rows.length > 0)
                out.push({ name: def.name, icon: def.icon, rows: rows })
        }

        const extra = []
        for (const k of Object.keys(c)) {
            if (!used[k])
                extra.push(Object.assign({ key: k }, formatValue(k, c[k])))
        }
        if (extra.length > 0)
            out.push({ name: "Other", icon: "ui/moreHoriz", rows: extra })

        return out
    }

    // Picks the most recently focused window that is not this inspector.
    // focusHistoryID 0 is the most recent, so while the inspector itself
    // has focus, the window we want is the next one in the history.
    function applyClients(raw) {
        let clients
        try {
            clients = JSON.parse(raw)
        } catch (e) {
            errorText = "Could not parse hyprctl output"
            client = null
            sections = []
            return
        }

        errorText = ""

        const candidates = clients
            .filter(c => c.mapped !== false && c.title !== win.title && c.focusHistoryID >= 0)
            .sort((a, b) => a.focusHistoryID - b.focusHistoryID)

        client = candidates.length > 0 ? candidates[0] : null
        sections = buildSections(client)
    }

    function refresh() {
        if (clientsProcess.running)
            needsRerun = true
        else
            clientsProcess.running = true
    }

    Process {
        id: clientsProcess
        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            onStreamFinished: win.applyClients(text)
        }

        onRunningChanged: {
            if (!running && win.needsRerun) {
                win.needsRerun = false
                running = true
            }
        }
    }

    // Hyprland events can arrive in bursts, so wait briefly before refreshing
    Timer {
        id: refreshTimer
        interval: 80
        onTriggered: win.refresh()
    }

    // Live tracking: any Hyprland event while open triggers a refresh
    Connections {
        target: Hyprland
        enabled: win.visible

        function onRawEvent(event) {
            refreshTimer.restart()
        }
    }

    onVisibleChanged: {
        if (visible) {
            refresh()
            focusScope.forceActiveFocus()
        } else if (IpcState.windowRules.isOpen) {
            // Closed from outside (e.g. compositor kill), keep state in sync
            IpcState.windowRules.close()
        }
    }

    // Material symbol drawn from the SVG icon set, tinted to a theme color
    component TintedIcon: Item {
        id: tinted

        property string name: ""
        property color tint: Colors.colors.foreground

        implicitWidth: 18
        implicitHeight: 18

        Image {
            id: iconImage
            anchors.fill: parent
            source: tinted.name !== "" ? Icons.getIcon(tinted.name) : ""
            sourceSize: Qt.size(64, 64)
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: iconImage
            colorization: 1.0
            colorizationColor: tinted.tint
        }
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: IpcState.windowRules.close()

        Rectangle {
            id: winRect

            anchors.fill: parent
            radius: 14
            color: Colors.colors.background
            border.color: Colors.colors.border
            border.width: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header, also acts as the drag handle
                Item {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onPressed: (mouse) => win.startSystemMove()
                    }

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        spacing: 10

                        TintedIcon {
                            name: "ui/selectWindow"
                            tint: Colors.colors.accent
                            implicitWidth: 24
                            implicitHeight: 24
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Window Rules"
                                color: Colors.colors.foreground
                                font.pixelSize: 16
                                font.family: Config.font
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: win.client
                                    ? (win.client.class || win.client.initialClass || "(no class)")
                                    : "No window"
                                color: Colors.colors.foregroundSubtle
                                font.pixelSize: 12
                                font.family: Config.font
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 14
                            color: closeArea.containsMouse ? Colors.colors.hover : "transparent"

                            TintedIcon {
                                anchors.centerIn: parent
                                name: "ui/close"
                                tint: Colors.colors.foregroundMuted
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: IpcState.windowRules.close()
                            }
                        }
                    }
                }

                // Empty or error state
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    visible: win.sections.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: win.errorText !== ""
                        ? win.errorText
                        : "No other window has been focused yet."
                    color: win.errorText !== "" ? Colors.colors.error : Colors.colors.foregroundSubtle
                    font.pixelSize: 13
                    font.family: Config.font
                }

                Flickable {
                    id: flick

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: win.sections.length > 0
                    clip: true
                    contentWidth: width
                    contentHeight: content.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: content

                        width: flick.width
                        spacing: 8

                        Repeater {
                            model: win.sections

                            delegate: Rectangle {
                                id: card

                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: cardColumn.implicitHeight + 24
                                radius: 10
                                color: Colors.colors.surfaceAlt

                                ColumnLayout {
                                    id: cardColumn

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 12
                                    }
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8

                                        TintedIcon {
                                            name: card.modelData.icon
                                            tint: Colors.colors.accentAlt
                                        }

                                        Text {
                                            text: card.modelData.name
                                            color: Colors.colors.accentAlt
                                            font.pixelSize: 13
                                            font.family: Config.font
                                            font.bold: true
                                        }
                                    }

                                    Repeater {
                                        model: card.modelData.rows

                                        delegate: RowLayout {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                Layout.preferredWidth: 130
                                                Layout.alignment: Qt.AlignTop
                                                text: modelData.key
                                                color: Colors.colors.foregroundMuted
                                                font.pixelSize: 12
                                                font.family: Config.font
                                                wrapMode: Text.WrapAnywhere
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignTop
                                                text: modelData.text
                                                font.pixelSize: 12
                                                font.family: "monospace"
                                                wrapMode: Text.WrapAnywhere
                                                color: modelData.kind === "on" ? Colors.colors.success
                                                     : modelData.kind === "off" ? Colors.colors.foregroundSubtle
                                                     : modelData.kind === "empty" ? Colors.colors.foregroundDisabled
                                                     : Colors.colors.foreground
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
