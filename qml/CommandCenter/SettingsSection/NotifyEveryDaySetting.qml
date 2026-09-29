// qml/CommandCenter/SettingsSection/NotifyEveryDaySetting.qml

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

    SettingToggle {
        settingText: "Every Day"
        description: "Check again every 24 hours and notify if package updates are available."
        checked: Config.pendingPackagesNotifyEveryDay
        onToggled: (value) => Config.stagePackagesNotifyEveryDay(value)
    }
}
