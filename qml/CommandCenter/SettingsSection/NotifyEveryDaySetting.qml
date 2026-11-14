// qml/CommandCenter/SettingsSection/NotifyEveryDaySetting.qml

import QtQuick
import "../../Config"
import "SettingsComponents"

SettingItem {
    id: root
    name: "Every Day"

    SettingToggle {
        settingText: root.name
        description: "Check again every 24 hours and notify if package updates are available."
        checked: Config.pendingPackagesNotifyEveryDay
        modified: Config.pendingPackagesNotifyEveryDay !== Config.packagesNotifyEveryDay
        onToggled: (value) => Config.stagePackagesNotifyEveryDay(value)
    }
}
