// qml/CommandCenter/SettingsSection/OSDScaleSizeSetting.qml

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
        settingText: "OSD Scale Size"
        textFieldText: Config.pendingOSDScaleSize
        modified: Config.pendingOSDScaleSize !== Config.osdScaleSize
        textFieldPlaceholder: "1.0"

        onEditingFinished: (text) => Config.stageOSDScaleSize(parseFloat(text, 10))
        onAccepted: (text) => Config.stageOSDScaleSize(parseFloat(text, 10))
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

        text: "Scale Size (Clamped between 0,4) " + (Config.pendingOSDScaleSize).toFixed(1)
    }
}
