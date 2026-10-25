// qml/CommandCenter/SettingsSection/NotificationToastDurationSetting.qml

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
        id: toastField
        settingText: "Toast Duration (ms)"
        textFieldText: Config.pendingNotificationToastMs
        modified: Config.pendingNotificationToastMs !== Config.notificationToastMs
        textFieldPlaceholder: "2000"

        onEditingFinished: (text) => Config.stageNotificationToastMs(parseInt(text, 10))
        onAccepted: (text) => Config.stageNotificationToastMs(parseInt(text, 10))
    }

    Text {
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: toastField.labelWidth + toastField.rowSpacing
        Layout.preferredWidth: toastField.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: Config.pendingFont
        color: Colors.colors.accentAlt

        text: "Toasts stay for " + (Config.pendingNotificationToastMs / 1000).toFixed(1) + "s"
    }
}
