// qml/CommandCenter/SettingsSection/OSDOrientationSetting.qml

import QtQuick
import "../../Config"
import "SettingsComponents"

SettingItem {
    id: root
    name: "OSD Orientation"

    readonly property var presets: [
        { label: "Top", value: "top" },
        { label: "Bottom", value: "bottom" }
    ]

    SettingComboBox {
        settingText: root.name
        pendingValue: Config.pendingOSDOrientation
        modified: Config.pendingOSDOrientation !== Config.osdOrientation
        presets: root.presets
        onActivated: (value) => Config.stageOSDOrientation(value)
    }
}
