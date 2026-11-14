// qml/CommandCenter/SettingsSection/ThemeSubSection/RunMatugenSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Run Matugen"

    SettingToggle {
        settingText: root.name
        description: "Run Matugen after selecting a wallpaper"
        checked: Config.pendingRunMatugen
        modified: Config.pendingRunMatugen !== Config.runMatugen
        onToggled: (value) => Config.stageRunMatugen(value)
    }
}

