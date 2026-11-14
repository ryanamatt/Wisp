// qml/CommandCenter/SettingsSection/FontSubSection/FontSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Wisp Font"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingFont
        textFieldPlaceholder: "Noto Sans Mono"
        modified: Config.pendingFont !== Config.font

        // The one preview that should render in the staged font
        previewText: "This is what your font looks like."
        previewFontFamily: Config.pendingFont

        onEditingFinished: (text) => Config.stageFont(text)
        onAccepted: (text) => Config.stageFont(text)
    }
}
