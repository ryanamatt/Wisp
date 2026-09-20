// qml/CommandCenter/SettingsSection/FontSetting.qml

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
        id: fontTextField
        settingText: "Wisp Font"
        textFieldText: Config.pendingFont
        textFieldPlaceholder: "Noto Sans Mono"

        onEditingFinished: (text) => Config.stageFont(text)
        onAccepted: (text) => Config.stageFont(text)
    }


    Text {
        id: previewText
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: fontTextField.labelWidth + fontTextField.rowSpacing
        Layout.preferredWidth: fontTextField.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: Config.pendingFont
        color: Colors.colors.accentAlt

        text: "This is what your font looks like."
    }
}
