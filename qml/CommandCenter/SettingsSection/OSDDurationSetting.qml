// qml/CommandCenter/OSDDurationSetting.qml

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
        id: textField

        settingText: "OSD Duration (ms)"
        textFieldText: Config.pendingOSDDuration
        modified: Config.pendingOSDDuration !== Config.osdDuration
        textFieldPlaceholder: "1000"
        onEditingFinished: (text) => Config.stageOSDDuration(parseInt(text, 10))
        onAccepted: (text) => Config.stageOSDDuration(parseInt(text, 10))
    }

    Text {
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: textField.labelWidth + textField.rowSpacing
        Layout.preferredWidth: textField.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: Config.pendingFont
        color: Colors.colors.accentAlt
        text: "OSD's stay for " + (Config.pendingOSDDuration / 1000).toFixed(1) + "s"
    }
}

