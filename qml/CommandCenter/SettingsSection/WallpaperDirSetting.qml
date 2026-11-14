// qml/CommandCenter/SettingsSection/WallpaperDirSetting.qml

import QtQuick
import "../../Config"
import "SettingsComponents"

SettingItem {
    id: root
    name: "Wallpaper Directory"

    SettingTextField {
        settingText: root.name
        textFieldText: Config.pendingWallpaperDirectory
        textFieldPlaceholder: "~/Pictures/wallpapers"
        modified: Config.pendingWallpaperDirectory !== Config.wallpaperDirectory
        previewText: Config.expandPath(Config.pendingWallpaperDirectory)

        onEditingFinished: (text) => Config.stageWallpaperDirectory(text)
        onAccepted: (text) => Config.stageWallpaperDirectory(text)
    }
}
