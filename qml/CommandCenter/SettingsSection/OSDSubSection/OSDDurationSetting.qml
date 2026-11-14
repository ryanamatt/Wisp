// qml/CommandCenter/SettingsSection/OSDSubSection/OSDDurationSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "OSD Duration (ms)"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingOSDDuration
        textFieldPlaceholder: "1000"
        modified: Config.pendingOSDDuration !== Config.osdDuration
        previewText: "OSD's stay for " + (Config.pendingOSDDuration / 1000).toFixed(1) + "s"

        onEditingFinished: (text) => Config.stageOSDDuration(parseInt(text, 10))
        onAccepted: (text) => Config.stageOSDDuration(parseInt(text, 10))
    }
}
