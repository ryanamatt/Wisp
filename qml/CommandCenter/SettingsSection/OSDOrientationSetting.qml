// qml/CommandCenter/SettingsSection/OSDOrientationSetting.qml

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
        settingText: "OSD Orientation"
        pendingValue: Config.pendingOSDOrientation
        modified: Config.pendingOSDOrientation !== Config.osdOrientation
        presets: root.presets
        onActivated: (value) => Config.stageOSDOrientation(value)
    }
}
