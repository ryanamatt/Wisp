// qml/CommandCenter/SettingsSection/OSDSubSection/OSDScaleSizeSetting.qml

import QtQuick
import "../../../Config"
import "../SettingsComponents"

SettingItem {
    id: root
    name: "OSD Scale Size"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingOSDScaleSize
        textFieldPlaceholder: "1.0"
        modified: Config.pendingOSDScaleSize !== Config.osdScaleSize
        previewText: "Scale Size (Clamped between 0,4) " + Config.pendingOSDScaleSize.toFixed(1)

        onEditingFinished: (text) => Config.stageOSDScaleSize(parseFloat(text))
        onAccepted: (text) => Config.stageOSDScaleSize(parseFloat(text))
    }
}
