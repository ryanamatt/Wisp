// qml/CommandCenter/SettingsSection/BarSubSection/BarOrientationSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Bar Orientation"

    readonly property var presets: [
        { label: "Top", value: "top" },
        { label: "Bottom", value: "bottom" }
    ]

    SettingComboBox {
        settingText: root.name
        pendingValue: Config.pendingBarOrientation
        modified: Config.pendingBarOrientation !== Config.barOrientation
        presets: root.presets
        onActivated: (value) => Config.stageBarOrientation(value)
    }
}
