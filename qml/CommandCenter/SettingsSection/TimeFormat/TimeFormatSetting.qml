// qml/CommandCenter/SettingsSection/TimeFormat/TimeFormatSetting.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../Colors"
import "../../../Config"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    // Presets shown in the dropdown. If the active format doesn't match
    // one of these, a trailing "Custom" entry is added so nothing is lost.
    readonly property var presets: [
        { label: "Weekday, date & time (12h)", value: "ddd MMM d hh:mm:ss AP" },
        { label: "Weekday, date & time (24h)", value: "ddd MMM d HH:mm:ss" },
        { label: "Date & time (12h)", value: "MMM d hh:mm AP" },
        { label: "Time only (12h)", value: "hh:mm AP" },
        { label: "Time only (24h)", value: "HH:mm" },
        { label: "ISO-like", value: "yyyy-MM-dd HH:mm:ss" }
    ]

    function indexForFormat(format) {
        for (let i = 0; i < presets.length; i++) {
            if (presets[i].value === format) return i
        }
        return -1
    }

    readonly property var fullModel: {
        const idx = indexForFormat(Config.pendingTimeFormat)
        if (idx !== -1) return presets
        return presets.concat([{ label: "Custom", value: Config.pendingTimeFormat }])
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 14

        Text {
            text: "Time Format"
            font.pixelSize: 15
            font.family: Config.font
            font.bold: true
            color: Colors.colors.foregroundMuted
        }

        ComboBox {
            id: timeFormatSetting

            Layout.preferredWidth: 240
            implicitHeight: 32

            model: root.fullModel
            textRole: "label"

            currentIndex: {
                const idx = root.indexForFormat(Config.pendingTimeFormat)
                return idx !== -1 ? idx : root.fullModel.length - 1
            }

            onActivated: (index) => Config.stageTimeFormat(root.fullModel[index].value)

            background: Rectangle {
                implicitHeight: 32
                radius: 8
                color: Colors.colors.surfaceAlt
                border.width: 1
                border.color: timeFormatSetting.hovered ? Colors.colors.borderActive : Colors.colors.border
            }

            contentItem: Text {
                text: timeFormatSetting.displayText
                font.pixelSize: 12
                font.family: Config.font
                color: Colors.colors.foreground
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }

            indicator: Text {
                x: timeFormatSetting.width - width - 10
                y: (timeFormatSetting.height - height) / 2
                text: "\u25BE"
                color: Colors.colors.foregroundMuted
            }

            delegate: ItemDelegate {
                required property var modelData
                required property int index

                width: timeFormatSetting.width
                height: 30

                background: Rectangle {
                    radius: 6
                    color: timeFormatSetting.highlightedIndex === index ? Colors.colors.hover : "transparent"
                }

                contentItem: Text {
                    text: modelData.label
                    font.pixelSize: 12
                    font.family: Config.font
                    color: Colors.colors.foreground
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
            }

            popup: Popup {
                y: timeFormatSetting.height + 4
                width: timeFormatSetting.width
                implicitHeight: contentItem.implicitHeight
                padding: 4

                background: Rectangle {
                    radius: 8
                    color: Colors.colors.surface
                    border.width: 1
                    border.color: Colors.colors.border
                }

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: timeFormatSetting.popup.visible ? timeFormatSetting.delegateModel : null
                    currentIndex: timeFormatSetting.highlightedIndex
                    boundsBehavior: Flickable.StopAtBounds
                }
            }
        }
    }

    Text {
        id: previewText
        Layout.alignment: Qt.AlignHCenter
        font.pixelSize: 12
        font.family: Config.font
        color: Colors.colors.accentAlt

        text: {
            clockTick.tick // re-evaluate every second
            return Qt.formatDateTime(new Date(), Config.pendingTimeFormat)
        }

        Timer {
            id: clockTick
            property int tick: 0
            interval: 1000
            running: true
            repeat: true
            onTriggered: tick++
        }
    }
}
