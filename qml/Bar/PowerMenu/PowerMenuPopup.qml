// qml/Bar/PowerMenu/PowerMenuPopup.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../Colors"

Rectangle {
    id: powerMenuPopup
    color: "transparent"
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    focus: true

    signal requestClose()
    property int currentIndex: 0

    function resetSelection() {
        powerMenuPopup.currentIndex = 0
    }

    property var actions: [
        {
            id: "lock",
            label: "Lock",
            glyph: "\uf023",
            colorKey: "accent",
            command: ["hyprlock"]
        },
        {
            id: "sleep",
            label: "Sleep",
            glyph: "\uf186",
            colorKey: "info",
            command: ["systemctl", "suspend"]
        },
        {
            id: "logout",
            label: "Log Out",
            glyph: "\uf2f5",
            colorKey: "accentAlt",
            command: ["hyprctl", "dispatch", "exit"]
        },
        {
            id: "reboot",
            label: "reboot",
            glyph: "\uf2f1",
            colorKey: "warning",
            command: ["systemctl", "reboot"]
        },
        {
            id: "shutdown",
            label: "Shut Down",
            glyph: "\uf011",
            colorKey: "error",
            command: ["systemctl", "poweroff"]
        }
    ]

    function colorFor(action) {
        return Colors.colors[action.colorKey] || Colors.colors.error
    }

    function runAction(action) {
        actionProc.command = action.command
        actionProc.running = true
    }

    Process {
        id: actionProc
    }

    function moveSelection(delta) {
        let newIndex = powerMenuPopup.currentIndex + delta
        let length = powerMenuPopup.actions.length
        powerMenuPopup.currentIndex = (newIndex % length + length) % length
    }

    function runSelection() {
        const action = powerMenuPopup.actions[powerMenuPopup.currentIndex]
        runAction(action)
    }

    Keys.onLeftPressed:   moveSelection(-1)
    Keys.onRightPressed:  moveSelection(1)
    Keys.onEscapePressed: powerMenuPopup.requestClose()
    Keys.onReturnPressed: runSelection()
    Keys.onEnterPressed:  runSelection()

    RowLayout {
        anchors.fill: parent

        Repeater {
            id: repeater
            model: powerMenuPopup.actions

            property int buttons: actions.length

            delegate: Rectangle {
                id: tile

                required property var modelData

                required property int index

                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property bool selected: index === powerMenuPopup.currentIndex

                color: selected ? Colors.colors.hover : Colors.colors.backgroundAlt
                border.width: selected ? 3 : 1
                border.color: powerMenuPopup.colorFor(modelData)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: modelData.glyph
                        font.family: "Iosevka Nerd Font Propo"
                        font.pixelSize: 32
                        color: powerMenuPopup.colorFor(modelData)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: powerMenuPopup.currentIndex = tile.index
                    onClicked: {
                        powerMenuPopup.currentIndex = tile.index
                        powerMenuPopup.runAction(modelData)
                    }
                }

            }

        }
    }
}