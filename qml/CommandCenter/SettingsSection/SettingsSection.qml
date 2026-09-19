// qml/CommandCenter/SettingsSection/SettingsSection.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../Colors"
import "../../Config"
import "SettingsComponents"

ColumnLayout {
    id: rootLayout

    anchors.fill: parent
    clip: true
    spacing: 30

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Wisp Settings"
            font.pixelSize: 25
            font.family: Config.font
            font.bold: true
            color: Colors.colors.accent
        }

        Text {
            text: "Customize Wisp to Your Heart's Delight!"
            font.pixelSize: 10
            font.family: Config.font
            color: Colors.colors.accent
        }

    }

    ScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 20

            SettingsSubSection {
                Layout.fillWidth: true
                sectionLabel: "Bar Settings"

                TimeFormatSetting { Layout.fillWidth: true }
                BarOrientationSetting { Layout.fillWidth: true }
            }

            SettingsSubSection {
                Layout.fillWidth: true
                sectionLabel: "Theme"

                WallpaperDirSetting { Layout.fillWidth: true }
            }
        }

    }

    Item { Layout.fillHeight: true }

    // ----- Global save bar -----
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.bottomMargin: 10
        spacing: 10

        Rectangle {
            id: saveButton

            readonly property bool active: Config.dirty

            Layout.preferredWidth: 100
            Layout.preferredHeight: 32
            radius: 8

            color: active ? (saveArea.pressed ? Colors.colors.accentAlt : Colors.colors.accent)
                          : Colors.colors.surfaceAlt
            border.width: 1
            border.color: active ? Colors.colors.borderActive : Colors.colors.border

            Text {
                anchors.centerIn: parent
                text: "Save"
                font.pixelSize: 13
                font.bold: true
                font.family: Config.font
                color: saveButton.active ? Colors.colors.background : Colors.colors.foregroundMuted
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                enabled: saveButton.active
                cursorShape: saveButton.active ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Config.save()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Config.dirty
            text: "You have unsaved changes"
            font.pixelSize: 11
            font.family: Config.font
            color: Colors.colors.warning
        }
    }
}
