// qml/CommandCenter/SettingsSection/TimeFormat/TimeFormatSetting.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../Colors"
import "../../../Config"
import "../../../Icons"
import "../SettingsComponents"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    readonly property var presets: [
        { label: "Weekday, date & time (12h)", value: "ddd MMM d hh:mm:ss AP" },
        { label: "Weekday, date & time (24h)", value: "ddd MMM d HH:mm:ss" },
        { label: "Date & time (12h)", value: "MMM d hh:mm AP" },
        { label: "Time only (12h)", value: "hh:mm AP" },
        { label: "Time only (24h)", value: "HH:mm" },
        { label: "ISO-like", value: "yyyy-MM-dd HH:mm:ss" }
    ]

    SettingComboBox {
        settingText: "Time Format"
        pendingValue: Config.pendingTimeFormat
        presets: root.presets
        onActivated: (value) => Config.stageTimeFormat(value)
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
