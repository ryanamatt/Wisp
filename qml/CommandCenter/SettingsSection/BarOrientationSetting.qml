// qml/CommandCenter/SettingsSection/BarOrientationSetting.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Config"
import "SettingsComponents"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    readonly property var presets: [
        { label: "Top", value: "top" },
        { label: "Bottom", value: "bottom" }
    ]

    SettingComboBox {
        settingText: "Bar Orientation"
        pendingValue: Config.pendingBarOrientation
        presets: root.presets
        onActivated: (value) => Config.stageBarOrientation(value)
    }
}
