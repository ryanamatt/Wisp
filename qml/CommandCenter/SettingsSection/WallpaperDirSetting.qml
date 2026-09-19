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

    // Shared metrics, kept consistent with SettingComboBox
    readonly property int labelWidth: 160
    readonly property int controlWidth: 240
    readonly property int rowSpacing: 14
    readonly property int controlHeight: 32
    readonly property int controlRadius: 8
    readonly property int controlBorderWidth: 1

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
        spacing: root.rowSpacing

        Text {
            text: "Wallpaper Directory"
            font.pixelSize: 15
            font.family: Config.font
            font.bold: true
            color: Colors.colors.foregroundMuted

            Layout.preferredWidth: root.labelWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }

        TextField {
            id: dirField

            Layout.preferredWidth: root.controlWidth
            implicitHeight: root.controlHeight

            text: Config.pendingWallpaperDirectory
            placeholderText: "~/Pictures/wallpapers"
            selectByMouse: true

            font.pixelSize: 12
            font.family: Config.font
            color: Colors.colors.foreground
            leftPadding: 10
            verticalAlignment: TextInput.AlignVCenter

            background: Rectangle {
                radius: root.controlRadius
                color: Colors.colors.surfaceAlt
                border.width: root.controlBorderWidth
                border.color: dirField.activeFocus ? Colors.colors.borderActive : Colors.colors.border
            }

            onEditingFinished: Config.stageWallpaperDirectory(text)
            onAccepted: Config.stageWallpaperDirectory(text)
        }
    }

    Text {
        id: previewText
        Layout.alignment: Qt.AlignLeft
        Layout.leftMargin: root.labelWidth + root.rowSpacing
        Layout.preferredWidth: root.controlWidth
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
