// qml/CommandCenter/SettingsSection/WallpaperDirSetting.qml

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
        id: wallpaperDirTextField
        settingText: "Wallpaper Directory"
        textFieldText: Config.pendingWallpaperDirectory
        textFieldPlaceholder: "~/Pictures/wallpapers"

        onEditingFinished: (text) => Config.stageWallpaperDirectory(text)
        onAccepted: (text) => Config.stageWallpaperDirectory(text)
    }


    Text {
        id: previewText
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: wallpaperDirTextField.labelWidth + wallpaperDirTextField.rowSpacing
        Layout.preferredWidth: wallpaperDirTextField.controlWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAnywhere

        font.pixelSize: 11
        font.family: Config.font
        color: Colors.colors.accentAlt

        text: {
            const dir = Config.pendingWallpaperDirectory
            return dir.startsWith("~") ? dir.replace("~", Config.home) : dir
        }
    }
}
