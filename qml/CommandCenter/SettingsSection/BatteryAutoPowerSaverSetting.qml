// qml/CommandCenter/SettingsSection/BatteryAutoPowerSaverSetting.qml

import QtQuick
import "../../Config"
import "SettingsComponents"

SettingItem {
    id: root
    name: "Auto Power Saver"

    SettingToggle {
        settingText: root.name
        description: "Switch to the Power Saver profile when the laptop battery drops to "
            + Config.pendingBatteryWarnPerc + "% and isn't charging."
        checked: Config.pendingBatteryAutoPowerSaver
        modified: Config.pendingBatteryAutoPowerSaver !== Config.batteryAutoPowerSaver
        onToggled: (value) => Config.stageBatteryAutoPowerSaver(value)
    }
}
