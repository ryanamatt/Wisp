// qml/CommandCenter/SettingsSection/PackagesSubSection/NotifyOnStartUpSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "On Startup"

    SettingToggle {
        settingText: root.name
        description: "Send a notification if package updates are available shortly after Wisp starts."
        checked: Config.pendingPackagesNotifyOnStartUp
        modified: Config.pendingPackagesNotifyOnStartUp !== Config.packagesNotifyOnStartUp
        onToggled: (value) => Config.stagePackagesNotifyOnStartUp(value)
    }
}
