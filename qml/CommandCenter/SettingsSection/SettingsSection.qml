// qml/CommandCenter/SettingsSectioin/SettingsSection.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Colors"
import "../../Config"

ColumnLayout {
    id: rootLayout

    anchors.fill: parent
    clip: true
    spacing: 14

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        text: "Wisp Settings"
        font.pixelSize: 25
        font.family: Config.font
        font.bold: true
        color: Colors.colors.accent
    }

    RowLayout {
        id: timeFormatLayout
        Layout.alignment: Qt.AlignHCenter

        spacing: 10

        Text {
            text: "Time Format"
            font.pixelSize: 15
            font.family: Config.font
            color: Colors.colors.foregroundMuted
        }

        ComboBox {
            id: timeFormatSetting
            model: ["Hello", "World", "Test"]

        }

    }

    Item { Layout.fillHeight: true }
}