// qml/CommandCenter/SettingsSection/NotificationToastDurationSetting.qml

import QtQuick
import "../../Config"
import "SettingsComponents"

SettingItem {
    id: root
    name: "Toast Duration (ms)"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingNotificationToastMs
        textFieldPlaceholder: "2000"
        modified: Config.pendingNotificationToastMs !== Config.notificationToastMs
        previewText: "Toasts stay for " + (Config.pendingNotificationToastMs / 1000).toFixed(1) + "s"

        onEditingFinished: (text) => Config.stageNotificationToastMs(parseInt(text, 10))
        onAccepted: (text) => Config.stageNotificationToastMs(parseInt(text, 10))
    }
}
