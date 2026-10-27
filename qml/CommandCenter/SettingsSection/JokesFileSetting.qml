// qml/CommandCenter/SettingsSection/JokesFileSetting.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Colors"
import "../../Config"
import "SettingsComponents"

ColumnLayout {
    id: root
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true

    spacing: 6

    SettingTextField {
        id: jokesFileTextField
        settingText: "Jokes File Path"
        textFieldText: Config.pendingJokesFilePath
        modified: Config.pendingJokesFilePath !== Config.jokesFilePath
        textFieldPlaceholder: "~/.config/wisp/jokes.txt"

        onEditingFinished: (text) => Config.stageJokesFilePath(text)
        onAccepted: (text) => Config.stageJokesFilePath(text)
    }


    Text {
        id: previewText
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: jokesFileTextField.labelWidth + jokesFileTextField.rowSpacing
        Layout.preferredWidth: jokesFileTextField.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: Config.font
        color: Colors.colors.accentAlt

        text: {
            const path = Config.pendingJokesFilePath
            return path.startsWith("~") ? path.replace("~", Config.home) : path
        }
    }
}
