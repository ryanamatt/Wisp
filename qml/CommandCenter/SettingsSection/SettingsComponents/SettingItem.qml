// qml/CommandCenter/SettingsSection/SettingsComponents/SettingItem.qml

import QtQuick
import QtQuick.Layouts

// Root type for every *Setting.qml file. One SettingItem is one searchable setting.
ColumnLayout {
    // Display name of the setting. Shown as the row label and intended to be
    // the primary search key. Add further search metadata here later.
    property string name: ""

    Layout.fillWidth: true
    spacing: 6
}
