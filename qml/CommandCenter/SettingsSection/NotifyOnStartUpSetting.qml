// qml/CommandCenter/SettingsSection/NotifyOnStartUpSetting.qml

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
        settingText: "On Startup"
        description: "Send a notification if package updates are available shortly after Wisp starts."
        checked: Config.pendingPackagesNotifyOnStartUp
        onToggled: (value) => Config.stagePackagesNotifyOnStartUp(value)
    }
}
