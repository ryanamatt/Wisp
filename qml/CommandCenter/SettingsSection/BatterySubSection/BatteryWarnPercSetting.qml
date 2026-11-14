// qml/CommandCenter/SettingsSection/BatterySubSection/BatteryWarnPercSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Warn At"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingBatteryWarnPerc
        textFieldPlaceholder: "30"
        modified: Config.pendingBatteryWarnPerc !== Config.batteryWarnPerc
        previewText: "Notify when a Battery is at " + Config.pendingBatteryWarnPerc + "%"

        onEditingFinished: (text) => Config.stageBatteryWarnPerc(parseInt(text, 10))
        onAccepted: (text) => Config.stageBatteryWarnPerc(parseInt(text, 10))
    }
}
