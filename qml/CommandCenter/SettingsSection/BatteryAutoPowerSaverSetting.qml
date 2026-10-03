// qml/CommandCenter/SettingsSection/BatteryAutoPowerSaverSetting.qml

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
        settingText: "Auto Power Saver"
        description: "Switch to the Power Saver profile when the laptop battery drops to "
            + Config.pendingBatteryWarnPerc + "% and isn't charging."
        checked: Config.pendingBatteryAutoPowerSaver
        onToggled: (value) => Config.stageBatteryAutoPowerSaver(value)
    }
}
