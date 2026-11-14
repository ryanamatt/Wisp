// qml/CommandCenter/SettingsSection/BarSubSection/TimeFormatSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Time Format"

    readonly property var presets: [
        { label: "Weekday, date & time (12h)", value: "ddd MMM d hh:mm:ss AP" },
        { label: "Weekday, date & time (24h)", value: "ddd MMM d HH:mm:ss" },
        { label: "Date & time (12h)", value: "MMM d hh:mm AP" },
        { label: "Time only (12h)", value: "hh:mm AP" },
        { label: "Time only (24h)", value: "HH:mm" },
        { label: "ISO-like", value: "yyyy-MM-dd HH:mm:ss" }
    ]

    // Bumped every second so the live preview re-evaluates
    property int tick: 0

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.tick++
    }

    SettingComboBox {
        settingText: root.name
        pendingValue: Config.pendingTimeFormat
        modified: Config.pendingTimeFormat !== Config.timeFormat
        presets: root.presets
        previewText: {
            root.tick
            return Qt.formatDateTime(new Date(), Config.pendingTimeFormat)
        }
        onActivated: (value) => Config.stageTimeFormat(value)
    }
}
