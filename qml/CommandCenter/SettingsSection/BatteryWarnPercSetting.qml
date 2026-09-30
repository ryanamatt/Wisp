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
        settingText: "Warn At"
        textFieldText: Config.pendingBatteryWarnPerc
        textFieldPlaceholder: "30"

        onEditingFinished: (text) => Config.stageBatteryWarnPerc(parseInt(text, 10))
        onAccepted: (text) => Config.stageBatteryWarnPerc(parseInt(text))
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

        text: "Notify when a Battery is at " + Config.pendingBatteryWarnPerc + "%"
    }
}
