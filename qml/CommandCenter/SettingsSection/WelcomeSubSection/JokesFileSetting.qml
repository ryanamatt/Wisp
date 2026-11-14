// qml/CommandCenter/SettingsSection/WelcomeSubSection/JokesFileSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "Jokes File Path"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingJokesFilePath
        textFieldPlaceholder: "~/.config/wisp/jokes.txt"
        modified: Config.pendingJokesFilePath !== Config.jokesFilePath
        previewText: Config.expandPath(Config.pendingJokesFilePath)

        onEditingFinished: (text) => Config.stageJokesFilePath(text)
        onAccepted: (text) => Config.stageJokesFilePath(text)
    }
}
